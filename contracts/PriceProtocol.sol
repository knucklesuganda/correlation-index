// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';


contract PriceOracle {
    address private uniswapV3PoolAddress;
    uint24 private twapDurationInSeconds;
    IUniswapV3Factory private factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    function getPrice(address tokenIn, address tokenOut, uint24 poolFee) external view returns (uint) {
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(tokenIn, tokenOut, poolFee));
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        return uint(sqrtPriceX96) * (uint(sqrtPriceX96) * 1e18) >> (96 * 2);
    }

}