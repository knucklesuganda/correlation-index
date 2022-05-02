// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract PriceOracle {
    using SafeMath for uint256;

    function getPrice(address priceAggregatorAddress) external view returns (uint) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(priceAggregatorAddress);
        (, int price,,,) = aggregator.latestRoundData();
        return uint256(price).mul(10000000000);
    }

}