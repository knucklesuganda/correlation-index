// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";


contract PriceOracle {
    function getPrice(address priceAggregatorAddress) public view returns (uint) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(priceAggregatorAddress);
        (, int price,,,) = aggregator.latestRoundData();
        return uint(price);
    }
}