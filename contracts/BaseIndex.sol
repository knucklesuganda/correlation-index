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
    struct TokenPrice{
        address token;
        string name;
        uint256 price;
    }

    struct TokenSwapPool{
        address tokenAddress;
        uint24 poolFee;
    }

    struct IndexInitialParameters{
        string tokenName;
        uint8 decimalUnits;
        uint initialAmount;
        string tokenSymbol;
        uint minimalFundAddition;
    }

    uint private totalLockedTokens;
    IndexToken public immutable indexToken;
    uint256 public immutable minimalFundAddition;
    address private immutable WETH;  // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    ISwapRouter private immutable uniswapRouter;    // 0xE592427A0AEce92De3Edee1F18E0157C05861564
    PriceOracle private priceOracle = new PriceOracle();
    BaseIndex.TokenSwapPool[] private immutable tokenContracts;

    constructor(
        BaseIndex.IndexInitialParameters memory params, BaseIndex.TokenSwapPool[] memory tokens, 
        address uniswapAddress, address wethAddress
    ){
        indexToken = new IndexToken(
            params.initialAmount, address(this), params.tokenName, params.decimalUnits, params.tokenSymbol
        );
        minimalFundAddition = params.minimalFundAddition;
        tokenContracts = tokens;

        uniswapRouter = ISwapRouter(uniswapAddress);
        WETH = wethAddress;
    }

    function calculatePrice(uint totalTokensPrice) private returns(uint){
        return totalTokensPrice / tokenContracts.length;
    }

    function buyToken(TokenSwapPool memory token, uint buyAmount) private returns(uint){
        uint tokenPrice = priceOracle.getPrice(token.tokenAddress, WETH, token.poolFee);
        uint tokenAmountOut = buyAmount * tokenPrice;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: token.tokenAddress,
            fee: token.poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: buyAmount,
            amountOutMinimum: tokenAmountOut,
            sqrtPriceLimitX96: 0
        });

        uniswapRouter.exactInputSingle{ value: buyAmount }(params);
        return tokenPrice; 
    }

    function addFunds() public payable {
        require(msg.value >= minimalFundAddition, "Not enough funds to add to the index");
        uint buyAmount = msg.value / tokenContracts.length;
        uint totalPrice;

        for (uint256 index = 0; index < tokenContracts.length; index++) {
            totalPrice += buyToken(tokenContracts[index], buyAmount);
        }

        uint tokensAmount = msg.value / calculatePrice(totalPrice);
        require(
            indexToken.balanceOf(address(this)) >= tokensAmount,
            "Not enough tokens in the index, you can only buy it on secondary markets"
        );

        totalLockedTokens += tokensAmount;
        indexToken.transferFrom(address(this), msg.sender, tokensAmount);
    }

    function getTokenPrices(address comparisonTokenAddress) public view returns (BaseIndex.TokenPrice[] memory) {
        BaseIndex.TokenPrice[] memory tokenPrices = new BaseIndex.TokenPrice[](tokenContracts.length);

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            address tokenAddress = tokenContracts[i].tokenAddress;
            ERC20 token = ERC20(tokenAddress);

            tokenPrices[i] = BaseIndex.TokenPrice({
                price: priceOracle.getPrice(tokenAddress, comparisonTokenAddress, tokenContracts[i].poolFee),
                name: token.symbol(),
                token: tokenAddress
            });
        }

        return tokenPrices;
    }

    function getIndexPrice(address comparisonTokenAddress) public view returns(uint){
        uint totalTokensPrice;

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            TokenSwapPool memory token = tokenContracts[i];
            totalTokensPrice += priceOracle.getPrice(token.tokenAddress, comparisonTokenAddress, token.poolFee);
        }

        return calculatePrice(totalTokensPrice);
    }

    function getTotalLockedValue(address comparisonTokenAddress) public view returns(uint){
        return totalLockedTokens * getIndexPrice(comparisonTokenAddress);
    }

    function getMyTokensPrice(address comparisonTokenAddress) public view returns(uint256){
        return indexToken.balanceOf(msg.sender) * getIndexPrice(comparisonTokenAddress);
    }

}
