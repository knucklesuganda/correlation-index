// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import './Token.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Index is Ownable {
    uint256 public totalFunds;
    mapping(address => uint256) public investors;
    uint256 private minimalFundAddition = 1000000000000000;
    string[] public tokens = ["WBTC", "ETH", "BNB", "MANA", "HBAR"];
    string[] private baseTokens = ["USD", "USD", "USD", "USD", "USD"];

    string public name = "Correlation Index";
    string public symbol = "CI";

    string private testnetPriceProtocol = 0xDA7a001b254CD22e46d3eAB04d937489c93174C3;
    PriceProtocol private priceProtocol = PriceProtocol(testnetPriceProtocol);

    function getPrice() public pure returns (uint256) {
        IStdReference.ReferenceData[] memory data = ref.getReferenceDataBulk(tokens, baseTokens,);

        uint256[] memory prices = new uint256[](2);
        prices[0] = data[0].rate;
        prices[1] = data[1].rate;

        uint256 totalPrice = 0;
        for (uint256 price in prices) {
            totalPrice += price;
        }

        return totalPrice / prices.length;
    }

    function addFunds() public payable {
        require(msg.value > minimalFundAddition, "You must send at least 1000000000000000 funds");
        totalFunds += msg.value;
        investors[msg.sender] += msg.value;

        // require(amount > 0, "You need to sell at least some tokens");
        // uint256 allowance = token.allowance(msg.sender, address(this));
        // require(allowance >= amount, "Check the token allowance");
        // token.transferFrom(msg.sender, address(this), amount);
        // msg.sender.transfer(amount);
        // emit Sold(amount);
    }

    function getTotalPrice() public payable returns(uint256){
        return totalFunds * getPrice();
    }

}