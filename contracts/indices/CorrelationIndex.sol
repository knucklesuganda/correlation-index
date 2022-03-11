// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import '../BaseIndex.sol';


contract CorrelationIndex is BaseIndex{
    constructor() BaseIndex(
        BaseIndex.IndexInitialParameters({
            tokenName: "Correlation Index Token",
            decimalUnits: 18,
            initialAmount: 1000000000000000,
            tokenSymbol: "CORRIN",
            minimalFundAddition: 1000
        }),
        0xE592427A0AEce92De3Edee1F18E0157C05861564,
        0x1F98431c8aD98523631AE4a59f267346ea31F984,
        0x6B175474E89094C44Da98b954EedeAC495271d0F
    ){
        tokenContracts.push(BaseIndex.TokenSwapPool({
            tokenAddress: 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0, poolFee: 3000     // MATIC
        }));
        tokenContracts.push(BaseIndex.TokenSwapPool({
            tokenAddress: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, poolFee: 3000     // UNI
        }));
        // tokenContracts.push(BaseIndex.TokenSwapPool({
        //     tokenAddress: 0xB8c77482e45F1F44dE1745F52C74426C631bDD52, poolFee: 3000     // BNB
        // }));
        // tokenContracts.push(BaseIndex.TokenSwapPool({
        //     tokenAddress: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, poolFee: 3000     // WBTC
        // }));
        // tokenContracts.push(BaseIndex.TokenSwapPool({
        //     tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA, poolFee: 3000     // LINK
        // }));
    }
}
