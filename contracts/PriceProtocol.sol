// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';


contract UniswapV3Oracle {
    address private uniswapV3PoolAddress;
    uint24 private twapDurationInSeconds;

    constructor(address pool) {
        uniswapV3PoolAddress = address(pool);
    }

    function getPrice() public view returns(uint32) {
        IUniswapV3Pool uniswapv3Pool = IUniswapV3Pool(uniswapV3PoolAddress);

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = 1;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = uniswapv3Pool.observe(secondAgos);

        int56 tickCumulativesDiff = tickCumulatives[1] - tickCumulatives[0];
        uint56 period = uint56(secondAgos[0] - secondAgos[1]);
        int56 timeWeightedAverageTick = (tickCumulativesDiff / -int56(period));
        uint8 decimalToken0 = ERC20(uniswapv3Pool.token0()).decimals();

        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(timeWeightedAverageTick));
        uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
        return uint32((ratioX192 * 1e18) >> (96 * 2));
    }
}