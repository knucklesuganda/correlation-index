// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './PriceProtocol.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";


contract BaseIndex is Ownable {

    uint256 private totalFunds;
    mapping(address => uint256) private investors;
    uint256 public minimalFundAddition;

    string[] public tokens;
    string public name;
    string public symbol;

    PriceConsumerV3[] public priceConsumers;
    IERC20[] public tokenContracts;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function getPrice() public view returns (uint256) {
        uint256 totalPrice = 0;

        for (uint256 index = 0; index < priceConsumers.length; index++) {
            PriceConsumerV3 consumer = priceConsumers[index];
            int256 latestPrice = consumer.getLatestPrice();
            totalPrice += uint256(latestPrice);
        }

        return totalPrice / priceConsumers.length;
    }

    function addFunds() public payable {
        require(msg.value > minimalFundAddition, "Not enough funds to add to the index");
        totalFunds += msg.value;
        investors[msg.sender] += msg.value / getPrice();

        address routerAddress = address(uniswapRouter);
        address indexAddress = address(this);

        for(uint index = 0; index < tokenContracts.length; index++) {
            IERC20 token = tokenContracts[index];
            uint256 tokenETHQuantity = msg.value / tokenContracts.length;
            uint256 tokenQuantity = tokenETHQuantity;
            token.approve(routerAddress, tokenETHQuantity);

            address[] memory path = new address[](2);
            path[0] = address(uniswapRouter.WETH());
            path[1] = address(token);

            uniswapRouter.swapExactETHForTokens(tokenQuantity, path, indexAddress, block.timestamp + 3600);
        }
    }

    function getTotalPrice() public payable returns(uint256){
        return totalFunds * getPrice();
    }

    function getMyTokensPrice() public view returns(uint256){
        return getMyTokens() * getPrice();
    }

    function getMyTokens() public view returns(uint256){
        return investors[msg.sender];
    }

}


contract CorrelationIndex is BaseIndex {

    constructor(){
        minimalFundAddition = 100000;
        tokens = ["BTC", "ETH", "BNB", "LINK", "DOT"];
        name = "Correlation Index";
        symbol = "CI";

        priceConsumers = [
            PriceConsumerV3(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE),    // BNB
            PriceConsumerV3(0x7CA57b0cA6367191c94C8914d7Df09A57655905f),    // MATIC
            PriceConsumerV3(0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf),    // WBTC
            PriceConsumerV3(0xca236E327F629f9Fc2c30A4E95775EbF0B89fac8),    // LINK
            PriceConsumerV3(0xF4C5e535756D11994fCBB12Ba8adD0192D9b88be),    // TRX
            PriceConsumerV3(0xb57f259E7C24e56a1dA00F66b55A5640d9f9E7e4)    // UNI
        ];

        tokenContracts = [
            IERC20(0xB8c77482e45F1F44dE1745F52C74426C631bDD52),     // BNB
            IERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0),     // MATIC
            IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599),     // WBTC
            IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA),     // LINK
            IERC20(0xE1Be5D3f34e89dE342Ee97E6e90D405884dA6c67),     // TRX
            IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984)     // UNI
        ];
    }

}
