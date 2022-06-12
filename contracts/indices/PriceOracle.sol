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

        uint160 sqrtRatioBX96 = uint160(sqrtPriceX96.add(sqrtPriceX96.mul(5)));
        uint160 sqrtRatioAX96 = uint160(sqrtPriceX96.sub(sqrtPriceX96));

        (uint amount0, uint amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, pool.liquidity()
        );
        return (amount0, amount1, pool.token0(), pool.token1());
    }

    function getMinimalPoolLiquidity(address firstToken, address secondToken, uint24 fee) private view returns(uint){
        (
            uint amount0,
            uint amount1,
            address token0,
            address token1
        ) = getPoolTokensAmount(firstToken, secondToken, fee);
        uint adjustedAmount;
        uint anotherAmount;

        if(token0 == firstToken){
            uint firstTokenPrice = getPrice(token0, token1, [fee, 0], address(0));
            adjustedAmount = amount1.mul(firstTokenPrice).div(1 ether);
            anotherAmount = amount0;
        }else{
            uint firstTokenPrice = getPrice(token1, token0, [fee, 0], address(0));
            adjustedAmount = amount0.mul(firstTokenPrice).div(1 ether);
            anotherAmount = amount1;
        }

        if(anotherAmount > adjustedAmount){
            return adjustedAmount;
        }else{
            return anotherAmount;
        }
    }

    function getLiquidity(
        address firstToken, address secondToken, uint24[2] memory tokenFees, address intermediateToken
    ) external view returns(uint){
        if(intermediateToken == address(0)){
            return getMinimalPoolLiquidity(firstToken, secondToken, tokenFees[0]);
        }else{
            uint firstPoolLiquidity = getMinimalPoolLiquidity(firstToken, intermediateToken, tokenFees[0]);
            uint secondPoolLiquidity = getMinimalPoolLiquidity(intermediateToken, secondToken, tokenFees[1]);

            uint price = getPrice(firstToken, intermediateToken, tokenFees, address(0));
            secondPoolLiquidity = secondPoolLiquidity.mul(price).div(1 ether);

            if(firstPoolLiquidity > secondPoolLiquidity){
                return secondPoolLiquidity;
            }else{
                return firstPoolLiquidity;
            }

        }

    }

    function getPrice(
        address firstToken, address secondToken, uint24[2] memory poolFees, address intermediateToken
    ) public view returns (uint) {

        if(intermediateToken == address(0)){
            int24 tick = getLatestTick(firstToken, secondToken, poolFees[0]);
            return OracleLibrary.getQuoteAtTick(tick, 1 ether, secondToken, firstToken);
        }else{
            int24 firstTick = getLatestTick(intermediateToken, secondToken, poolFees[1]);
            uint firstSwapPrice = OracleLibrary.getQuoteAtTick(firstTick, 1 ether, secondToken, intermediateToken);

            int24 secondTick = getLatestTick(firstToken, intermediateToken, poolFees[0]);
            uint secondSwapPrice = OracleLibrary.getQuoteAtTick(
                secondTick,
                uint128(firstSwapPrice),
                intermediateToken,
                firstToken
            );

            return secondSwapPrice;
        }

    }

}