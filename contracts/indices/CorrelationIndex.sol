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
            minimalFundAddition: 0
        }),
        0xE592427A0AEce92De3Edee1F18E0157C05861564,     // Uniswap V3 Router
        0x6B175474E89094C44Da98b954EedeAC495271d0F      // DAI
    ){
        tokenContracts.push(BaseIndex.TokenSwapPool({   // MATIC
            tokenAddress: 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,
            priceOracleAddress: 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676,
            poolFee: 3000
        }));
        tokenContracts.push(BaseIndex.TokenSwapPool({   // WBTC
            tokenAddress: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            priceOracleAddress: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c,
            poolFee: 3000
        }));
    }
}
