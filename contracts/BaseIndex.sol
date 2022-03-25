// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

import "./PriceOracle.sol";
import "./IndexToken.sol";



contract BaseIndex is Ownable{
    address public immutable dexRouterAddress;
    address public immutable buyTokenAddress;

    struct TokenInfo{
        address tokenAddress;
        address priceOracleAddress;
        uint24 poolFee;
        uint priceAdjustment;
    }

    TokenInfo[] public tokens;
    PriceOracle private priceOracle;
    IndexToken public indexToken;
    uint private _indexFee;

    constructor(){
        dexRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;     // Uniswap V3 Router
        buyTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;     // DAI
        _indexFee = 1;
        indexToken = new IndexToken(address(this), 10000000, "Index token", 18, "INDEX");
        priceOracle = new PriceOracle();

        tokens.push(TokenInfo({     // WETH
            tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            priceOracleAddress: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            poolFee: 3000,
            priceAdjustment: 1000000000
        }));
        tokens.push(TokenInfo({     // WBTC
            tokenAddress: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            priceOracleAddress: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c,
            poolFee: 3000,
            priceAdjustment: 1000000000
        }));
        // tokens.push(TokenInfo({       // MATIC
        //     tokenAddress: 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,
        //     priceOracleAddress: 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676,
        //     poolFee: 3000
        // }));
    }

    function indexFee() external view returns(uint){
        return _indexFee;
    }

    function calculateFee(uint amount) private view returns(uint, uint){
        uint indexFeeAmount = (amount / 100) * _indexFee;
        uint realAmount = amount - indexFeeAmount;
        return (indexFeeAmount, realAmount);
    }

    function addFunds(uint amount) external{
        uint indexPrice = getIndexPrice();

        (uint fee, uint realAmount) = calculateFee(amount);
        require(realAmount / indexPrice > 0, "You must add more funds to the index");

        TransferHelper.safeTransferFrom(buyTokenAddress, msg.sender, address(this), amount);
        TransferHelper.safeApprove(buyTokenAddress, dexRouterAddress, amount);
        IERC20(buyTokenAddress).transfer(owner(), fee);

        uint singleTokenAmount = realAmount / tokens.length;
        uint totalTokensAmount;
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        for (uint256 index = 0; index < tokens.length; index++) {            
            TokenInfo memory token = tokens[index];

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: buyTokenAddress,
                tokenOut: token.tokenAddress,
                fee: token.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: singleTokenAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            // 4000

            uint amountOut = dexRouter.exactInputSingle(params);
            totalTokensAmount += amountOut;
        }

        uint indexTokens = totalTokensAmount;
        indexToken.transfer(msg.sender, indexTokens);
    }

    function getIndexPrice() public view returns(uint){
        uint indexTotalPrice;

        for(uint i = 0; i < tokens.length; i++){
            TokenInfo memory token = tokens[i];
            uint price = priceOracle.getPrice(token.priceOracleAddress, token.priceAdjustment);
            indexTotalPrice += price;
        }

        return indexTotalPrice / tokens.length;
    }

    function withdrawFunds(uint indexAmount) external {
        require(indexAmount > 1, "You must withdraw more funds from the index");
        (uint fee, uint realAmount) = calculateFee(indexAmount);

        uint singleTokenAmount = indexAmount / tokens.length;

        TransferHelper.safeTransferFrom(address(indexToken), msg.sender, address(this), indexAmount);
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        for (uint256 index = 0; index < tokens.length; index++) {
            TokenInfo memory token = tokens[index];
            
            uint tokenPrice = priceOracle.getPrice(token.priceOracleAddress, token.priceAdjustment);
            uint tokenAmount = singleTokenAmount / tokenPrice; 

            TransferHelper.safeApprove(token.tokenAddress, dexRouterAddress, tokenAmount);

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token.tokenAddress,
                tokenOut: buyTokenAddress,
                fee: token.poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: tokenAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            dexRouter.exactInputSingle(params);
        }

    }

}
