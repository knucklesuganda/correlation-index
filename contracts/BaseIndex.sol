// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

import "./PriceOracle.sol";



contract BaseIndex{
    address public immutable dexRouterAddress;
    address public immutable buyTokenAddress;

    struct TokenInfo{
        address tokenAddress;
        address priceOracleAddress;
        uint24 poolFee;
    }

    TokenInfo[] public tokens;
    PriceOracle private priceOracle;
    ERC20 public indexToken;

    constructor(){
        dexRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;     // Uniswap V3 Router
        buyTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;     // DAI
        indexToken = new ERC20("Index", "IDX");
        priceOracle = new PriceOracle();

        tokens.push(TokenInfo({     // WETH
            tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            priceOracleAddress: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            poolFee: 3000
        }));
        tokens.push(TokenInfo({       // WBTC
            tokenAddress: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            priceOracleAddress: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c,
            poolFee: 3000
        }));
        // tokens.push(TokenInfo({       // MATIC
        //     tokenAddress: 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,
        //     priceOracleAddress: 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676,
        //     poolFee: 3000
        // }));
    }

    function addFunds(uint amount) external returns(uint){
        TransferHelper.safeTransferFrom(buyTokenAddress, msg.sender, address(this), amount);
        TransferHelper.safeApprove(buyTokenAddress, dexRouterAddress, amount);

        uint singleTokenAmount = amount / tokens.length;
        uint indexTotalPrice;

        for(uint i = 0; i < tokens.length; i++){
            TokenInfo memory token = tokens[i];
            uint price = priceOracle.getPrice(token.priceOracleAddress);
            indexTotalPrice += price;

            uint amountOut = singleTokenAmount / price;

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: buyTokenAddress,
                tokenOut: token.tokenAddress,
                fee: token.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: singleTokenAmount,
                amountOutMinimum: amountOut,
                sqrtPriceLimitX96: 0
            });

            ISwapRouter(dexRouterAddress).exactInputSingle(params);
        }

        uint indexAmount = amount / indexTotalPrice;
        indexToken.transfer(msg.sender, indexAmount);
        return indexAmount;
    }

}
