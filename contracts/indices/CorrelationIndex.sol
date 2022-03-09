// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import '../BaseIndex.sol';


contract CorrelationIndex is BaseIndex{
    constructor() BaseIndex(10000, "Correlation Index Token", 18, "CORRIN", 100, "Correlation Index", "CI"){
        tokenContracts = [
            // ETH mainnet
            address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0),     // MATIC
            address(0xE1Be5D3f34e89dE342Ee97E6e90D405884dA6c67),     // TRX
            address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984),     // UNI
            address(0xB8c77482e45F1F44dE1745F52C74426C631bDD52),     // BNB
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),    // WETH
            address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599),     // WBTC
            address(0x514910771AF9Ca656af840dff83E8264EcF986CA)     // LINK
        ];
    }
}
