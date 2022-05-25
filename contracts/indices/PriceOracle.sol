// // SPDX-License-Identifier: MIT
// pragma solidity 0.7.6;
// 
// import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
// import "@uniswap/v3
// import "@openzeppelin/contracts/math/SafeMath.sol";
// 
// 
// contract PriceOracle {
//     using SafeMath for uint256;
// 
//     function getPrice(address priceAggregatorAddress) external view returns (uint) {
//         AggregatorV3Interface aggregator = AggregatorV3Interface(priceAggregatorAddress);
//         (, int price,,,) = aggregator.latestRoundData();
//         return uint256(price).mul(10000000000);
//     }
// 
// }


// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract PriceOracle {
    using SafeMath for uint256;
    IUniswapV3Factory private factory;
    address baseToken;

    constructor(){
        factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        baseToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    }

    function getPrice2(address secondToken, uint24 poolFee) external view returns (uint) {
        IUniswapV3Pool uniswapv3Pool = IUniswapV3Pool(factory.getPool(baseToken, secondToken, poolFee));
        // (uint sqrtPriceX96, , , , , , ) = uniswapv3Pool.slot0();
        
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

        // sqrtRatioX96 ** 2 / 2 ** 192 = price
        return uint(sqrtRatioX96).mul(uint(sqrtRatioX96)).mul(1 ether).div(2 ** 192);
    }

    function getPrice(address a) pure public returns(uint){ return 100; }
}