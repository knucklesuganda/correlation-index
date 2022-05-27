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
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract PriceOracle {
    using SafeMath for uint256;
    IUniswapV3Factory private factory;
    address baseToken;
    address WETH;

    constructor(){
        factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        baseToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    function getPrice(
        address secondToken, uint24[2] memory poolFees, address intermediateToken
    ) external view returns (uint) {

        if(intermediateToken == address(0)){
            IUniswapV3Pool secondPool = IUniswapV3Pool(factory.getPool(baseToken, secondToken, poolFees[0]));
            (, int24 tick, ,,,, ) = secondPool.slot0();
            return OracleLibrary.getQuoteAtTick(tick, 1 ether, secondToken, baseToken);
        }

        IUniswapV3Pool firstPool = IUniswapV3Pool(factory.getPool(intermediateToken, secondToken, poolFees[1]));
        (, int24 firstTick, , , , , ) = firstPool.slot0();
        uint firstSwapPrice = OracleLibrary.getQuoteAtTick(firstTick, 1 ether, secondToken, intermediateToken);

        IUniswapV3Pool secondPool = IUniswapV3Pool(factory.getPool(baseToken, intermediateToken, poolFees[0]));
        (, int24 secondTick, , , , , ) = secondPool.slot0();
        uint secondSwapPrice = OracleLibrary.getQuoteAtTick(
            secondTick, uint128(firstSwapPrice), intermediateToken, baseToken
        );

        return secondSwapPrice;
    }

}