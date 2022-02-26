// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import './Token.sol';
import './PriceProtocol.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Index is Ownable {
    uint256 public totalFunds;
    mapping(address => uint256) public investors;
    uint256 private minimalFundAddition = 1000000000000000;

    string[] public tokens = ["BTC", "ETH", "BNB", "LINK", "DOT"];
    string[] private baseTokens = ["USD", "USD", "USD", "USD", "USD"];
    string public name = "Correlation Index";
    string public symbol = "CI";

    address private testnetPriceProtocol = 0xDA7a001b254CD22e46d3eAB04d937489c93174C3;
    PriceProtocol private priceProtocol = PriceProtocol(testnetPriceProtocol);

    IERC20[] public tokenContracts = [
        IERC20(0x64FF637fB478863B7468bc97D30a5bF3A428a1fD),     // ETH
        IERC20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47),     // CARDANO
        IERC20(0x1CE0c2827e2eF14D5C4f29a091d735A204794041),   // AVAX
        IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c),     // BTC
        IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)     // BNB
    ];

    function getPrice() public view returns (uint256) {
        PriceProtocol.ReferenceData[] memory priceData = priceProtocol.getReferenceDataBulk(tokens, baseTokens);
        uint256 totalPrice = 0;

        for (uint256 index = 0; index < priceData.length; index++) {
            totalPrice += priceData[index].rate;
        }

        return totalPrice / priceData.length;
    }

    function addFunds() public payable {
        require(msg.value > minimalFundAddition, "You must send at least 1000000000000000 funds");
        totalFunds += msg.value;
        investors[msg.sender] += msg.value;

        
    }

    function getTotalPrice() public payable returns(uint256){
        return totalFunds * getPrice();
    }

}