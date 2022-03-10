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
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        0x1F98431c8aD98523631AE4a59f267346ea31F984
    ){
        tokenContracts.push(BaseIndex.TokenSwapPool({
            tokenAddress: 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0, poolFee: 3000     // MATIC
        }));
        tokenContracts.push(BaseIndex.TokenSwapPool({
            tokenAddress: 0xE1Be5D3f34e89dE342Ee97E6e90D405884dA6c67, poolFee: 3000     // TRX
        }));
        tokenContracts.push(BaseIndex.TokenSwapPool({
            tokenAddress: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, poolFee: 3000     // UNI
        }));
        tokenContracts.push(BaseIndex.TokenSwapPool({
            tokenAddress: 0xB8c77482e45F1F44dE1745F52C74426C631bDD52, poolFee: 3000     // BNB
        }));
        tokenContracts.push(BaseIndex.TokenSwapPool({
            tokenAddress: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, poolFee: 3000     // WBTC
        }));
        tokenContracts.push(BaseIndex.TokenSwapPool({
            tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA, poolFee: 3000     // LINK
        }));
    }
}
