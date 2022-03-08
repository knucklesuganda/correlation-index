// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";


contract PriceProtocol {
    function getPrice(address uniswapV3Pool) public view returns (uint160) {
        ( uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
        return sqrtPriceX96;
    }
}