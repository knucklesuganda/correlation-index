// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract PriceOracle {
    using SafeMath for uint256;
    using SafeMath for uint160;

    IUniswapV3Factory private factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    function getLatestTick(address firstToken, address secondToken, uint24 fee) private view returns(int24){
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(firstToken, secondToken, fee));
        (, int24 tick, ,,,, ) = pool.slot0();
        return tick;
    }

    function getPoolTokensAmount(
        address firstToken, address secondToken, uint24 fee
    ) private view returns(uint, uint, address, address){
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(firstToken, secondToken, fee));
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        uint160 sqrtRatioBX96 = uint160(sqrtPriceX96.add(sqrtPriceX96.mul(10000)));
        uint160 sqrtRatioAX96 = uint160(sqrtPriceX96.sub(sqrtPriceX96));

        (uint amount0, uint amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, pool.liquidity()
        );
        return (amount0, amount1, pool.token0(), pool.token1());
    }


    function getLiquidity(address firstToken, address secondToken, uint24 tokenFee) external view returns(uint){
        (
            uint amount0,
            uint amount1,
            address token0,
            address token1
        ) = getPoolTokensAmount(firstToken, secondToken, tokenFee);
        uint adjustedAmount;
        uint anotherAmount;

        if(token0 == firstToken){
            uint firstTokenPrice = getPrice(token0, token1, tokenFee);
            adjustedAmount = amount1.mul(firstTokenPrice).div(1 ether);
            anotherAmount = amount0;
        }else{
            uint firstTokenPrice = getPrice(token1, token0, tokenFee);
            adjustedAmount = amount0.mul(firstTokenPrice).div(1 ether);
            anotherAmount = amount1;
        }

        if(anotherAmount > adjustedAmount){
            return adjustedAmount;
        }else{
            return anotherAmount;
        }
    }

    function getPrice(address firstToken, address secondToken, uint24 poolFee) public view returns (uint) {
        int24 tick = getLatestTick(firstToken, secondToken, poolFee);
        return OracleLibrary.getQuoteAtTick(tick, 1 ether, secondToken, firstToken);
    }

}