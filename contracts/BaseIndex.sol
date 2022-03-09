// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import './PriceProtocol.sol';
import './IndexToken.sol';


contract BaseIndex {

    uint256 public immutable minimalFundAddition;
    uint256 public totalTokens;

    string public name;
    string public symbol;
    address[] public tokenContracts;

    uint24 public constant poolFee = 3000;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    ISwapRouter private constant uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    PriceOracle private priceOracle = new PriceOracle();
    IndexToken public immutable indexToken;

    struct TokenPrice{
        address token;
        string name;
        uint256 price;
    }

    constructor(
        uint256 _initialAmount, string memory _tokenName,
        uint8 _decimalUnits, string  memory _tokenSymbol,
        uint _minimalFundAddition, string memory _indexName,
        string memory _indexSymbol
    ){
        indexToken = new IndexToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol);
        minimalFundAddition = _minimalFundAddition;
        name = _indexName;
        symbol = _indexSymbol;
    }

    function getTokenPrices(address comparisonTokenAddress) public view returns (BaseIndex.TokenPrice[] memory) {
        BaseIndex.TokenPrice[] memory tokenPrices = new BaseIndex.TokenPrice[](tokenContracts.length);

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            address tokenAddress = tokenContracts[i];
            ERC20 token = ERC20(tokenAddress);

            tokenPrices[i] = BaseIndex.TokenPrice({
                price: priceOracle.getPrice(tokenAddress, comparisonTokenAddress, poolFee),
                name: token.symbol(),
                token: tokenAddress
            });
        }

        return tokenPrices;
    }

    function getIndexPrice(address comparisonTokenAddress) public view returns(uint){
        uint indexPrice;

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            indexPrice += priceOracle.getPrice(tokenContracts[i], comparisonTokenAddress, poolFee);
        }

        return indexPrice / tokenContracts.length;
    }

    function addFunds() public payable {
        require(msg.value > minimalFundAddition, "Not enough funds to add to the index");

        for (uint256 index = 0; index < tokenContracts.length; index++) {
            uint _amountIn = msg.value / tokenContracts.length;
            uint tokenPrice = priceOracle.getPrice(tokenContracts[index], WETH, poolFee);
            uint amountOut = _amountIn * tokenPrice;

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: tokenContracts[index],
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: amountOut,
                sqrtPriceLimitX96: 0
            });

            uniswapRouter.exactInputSingle{ value: msg.value }(params);   
        }

        uint tokensAmount = msg.value / getIndexPrice(WETH);
        indexToken.transferFrom(address(this), msg.sender, tokensAmount);
        totalTokens += tokensAmount;
    }

    receive() payable external {}

    function getTVL(address comparisonTokenAddress) public view returns(uint256){
        return totalTokens * getIndexPrice(comparisonTokenAddress);
    }

    function getMyTokensPrice(address comparisonTokenAddress) public view returns(uint256){
        return indexToken.balanceOf(msg.sender) * getIndexPrice(comparisonTokenAddress);
    }

}
