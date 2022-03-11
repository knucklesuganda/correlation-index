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
    address private immutable buyTokenAddress;  // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    ISwapRouter private immutable uniswapRouter;    // 0xE592427A0AEce92De3Edee1F18E0157C05861564
    PriceOracle private priceOracle; // 0x1F98431c8aD98523631AE4a59f267346ea31F984
    BaseIndex.TokenSwapPool[] public tokenContracts;

    constructor(
        BaseIndex.IndexInitialParameters memory params,
        address uniswapAddress, address priceOracleAddress, address _buyTokenAddress
    ){
        indexToken = new IndexToken(
            params.initialAmount, address(this), params.tokenName, params.decimalUnits, params.tokenSymbol
        );
        minimalFundAddition = params.minimalFundAddition;
        uniswapRouter = ISwapRouter(uniswapAddress);
        buyTokenAddress = _buyTokenAddress;
        priceOracle = new PriceOracle(priceOracleAddress);
    }

    function calculatePrice(uint totalTokensPrice) private view returns(uint){
        return totalTokensPrice / tokenContracts.length;
    }

    function addFunds(uint amountIn) public{
        require(amountIn >= minimalFundAddition, "Not enough funds to add to the index");
        uint buyAmount = amountIn / tokenContracts.length;
        uint totalPrice;

        IERC20(buyTokenAddress).transferFrom(msg.sender, address(this), amountIn);
        IERC20(buyTokenAddress).approve(address(uniswapRouter), amountIn);

        for (uint256 index = 0; index < tokenContracts.length; index++) {
            TokenSwapPool memory token = tokenContracts[index];

            uint tokenPrice = priceOracle.getPrice(buyTokenAddress, token.tokenAddress, token.poolFee);
            uint tokenAmountOut = buyAmount * tokenPrice;

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: buyTokenAddress,
                tokenOut: token.tokenAddress,
                fee: token.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: buyAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            uniswapRouter.exactInputSingle(params);
            totalPrice += tokenPrice;
        }

        uint tokensAmount = amountIn / calculatePrice(totalPrice);
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
