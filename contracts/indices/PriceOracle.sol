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

    constructor(address _factoryAddress, address _baseToken, address _WETH){
        factory = IUniswapV3Factory(_factoryAddress);
        baseToken = _baseToken;
        WETH = _WETH;
    }

    function getLatestTick(address firstToken, address secondToken, uint24 fee) private view returns(int24){
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(firstToken, secondToken, fee));
        (, int24 tick, ,,,, ) = pool.slot0();
        return tick;
    }

    function getPrice(
        address secondToken, uint24[2] memory poolFees, address intermediateToken
    ) external view returns (uint) {

        if(intermediateToken == address(0)){
            int24 tick = getLatestTick(baseToken, secondToken, poolFees[0]);
            return OracleLibrary.getQuoteAtTick(tick, 1 ether, secondToken, baseToken);
        }else{
            int24 firstTick = getLatestTick(intermediateToken, secondToken, poolFees[1]);
            uint firstSwapPrice = OracleLibrary.getQuoteAtTick(firstTick, 1 ether, secondToken, intermediateToken);

            int24 secondTick = getLatestTick(baseToken, intermediateToken, poolFees[0]);
            uint secondSwapPrice = OracleLibrary.getQuoteAtTick(
                secondTick, uint128(firstSwapPrice), intermediateToken, baseToken
            );

            return secondSwapPrice;
        }

    }

}