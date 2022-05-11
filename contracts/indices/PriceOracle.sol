// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract PriceOracle {
    using SafeMath for uint256;
    IUniswapV3Factory private factory;
    address baseToken;

    constructor(address factoryAddress, address _baseToken){
        factory = IUniswapV3Factory(factoryAddress);
        baseToken = _baseToken;
    }

    function getPrice(address secondToken, uint24 poolFee) external view returns (uint) {
        IUniswapV3Pool uniswapv3Pool = IUniswapV3Pool(factory.getPool(baseToken, secondToken, poolFee));

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = 1;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = uniswapv3Pool.observe(secondAgos);

        int56 tickCumulativesDiff = tickCumulatives[1] - tickCumulatives[0];
        uint56 period = uint56(secondAgos[0]-secondAgos[1]);

        int56 timeWeightedAverageTick = (tickCumulativesDiff / -int56(period));

        uint8 decimalToken0 = ERC20(uniswapv3Pool.token0()).decimals();
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(timeWeightedAverageTick));
        uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
        
        uint32 price = uint32((ratioX192 * 1e18) >> (96 * 2));
        uint32 decimalAdjFactor = uint32(10**(decimalToken0));

        return uint(price);

    }

    function getPrice2(address secondToken, uint24 poolFee) external view returns (uint, uint) {
        IUniswapV3Pool uniswapv3Pool = IUniswapV3Pool(factory.getPool(baseToken, secondToken, poolFee));

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = 1;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = uniswapv3Pool.observe(secondAgos);

        int56 tickCumulativesDiff = tickCumulatives[1] - tickCumulatives[0];
        uint56 period = uint56(secondAgos[0]-secondAgos[1]);

        int56 timeWeightedAverageTick = (tickCumulativesDiff / -int56(period));

        uint8 decimalToken0 = ERC20(uniswapv3Pool.token0()).decimals();
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(timeWeightedAverageTick));
        uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
        
        uint price = (ratioX192.mul(1e18)) >> 96 * 2;
        uint decimalAdjFactor = 10 ** decimalToken0;

        return (price, decimalAdjFactor);

    }

}