// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

import "./PriceOracle.sol";
import "./IndexToken.sol";
import "./BaseProduct.sol";


contract BaseIndex is Product{
    address private immutable dexRouterAddress;

    struct TokenInfo{
        address tokenAddress;
        address priceOracleAddress;
        uint24 poolFee;
        uint priceAdjustment;
        uint withdrawAdjustment;
        uint8 indexPercentage;
    }

    TokenInfo[] public tokens;
    PriceOracle private priceOracle;
    IndexToken public indexToken;

    function name() external override pure returns(string memory){
        return 'CryptoIndex';
    }

    function symbol() external override pure returns(string memory){
        return 'CRYPTIX';
    }

    constructor(){
        dexRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;     // Uniswap V3 Router
        buyTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;     // USDC
        indexFee = 5;
        indexFeeTotal = 1000;
        indexPriceAdjustment = 100;
        indexToken = new IndexToken(address(this), "Crypto index token", 18, "CRYPTIX");
        priceOracle = new PriceOracle();
        isLocked = false;

        tokens.push(TokenInfo({     // WETH
            tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            priceOracleAddress: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            poolFee: 3000,
            priceAdjustment: 1,
            withdrawAdjustment: 100000000,
            indexPercentage: 40
        }));
        tokens.push(TokenInfo({     // WBTC
            tokenAddress: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            priceOracleAddress: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c,
            poolFee: 3000,
            priceAdjustment: 10000000000,
            withdrawAdjustment: 1,
            indexPercentage: 20
        }));
        tokens.push(TokenInfo({    // LINK
            tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            priceOracleAddress: 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c,
            poolFee: 3000,
            priceAdjustment: 1,
            withdrawAdjustment: 100000000,
            indexPercentage: 40
        }));

        // tokens.push(TokenInfo({    // UNI
        //     tokenAddress: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
        //     priceOracleAddress: 0x553303d460EE0afB37EdFf9bE42922D8FF63220e,
        //     poolFee: 3000,
        //     priceAdjustment: 1,
        //     withdrawAdjustment: 100000000
        // }));
        // tokens.push(TokenInfo({    // BNB
        //     tokenAddress: 0xB8c77482e45F1F44dE1745F52C74426C631bDD52,
        //     priceOracleAddress: 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A,
        //     poolFee: 3000,
        //     priceAdjustment: 1,
        //     withdrawAdjustment: 100000000
        // }));
        // tokens.push(TokenInfo({    //   SNX
        //     tokenAddress: 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
        //     priceOracleAddress: 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699,
        //     poolFee: 3000,
        //     priceAdjustment: 1,
        //     withdrawAdjustment: 100000000
        // }));
        // tokens.push(TokenInfo({    //   YFI
        //     tokenAddress: 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
        //     priceOracleAddress: 0xA027702dbb89fbd58938e4324ac03B58d812b0E1,
        //     poolFee: 3000,
        //     priceAdjustment: 1,
        //     withdrawAdjustment: 100000000
        // }));
        // tokens.push(TokenInfo({    //   COMP
        //     tokenAddress: 0xc00e94Cb662C3520282E6f5717214004A7f26888,
        //     priceOracleAddress: 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5,
        //     poolFee: 3000,
        //     priceAdjustment: 1,
        //     withdrawAdjustment: 100000000
        // }));
        // tokens.push(TokenInfo({    //   1INCH
        //     tokenAddress: 0x111111111117dC0aa78b770fA6A738034120C302,
        //     priceOracleAddress: 0xc929ad75B72593967DE83E7F7Cda0493458261D9,
        //     poolFee: 3000,
        //     priceAdjustment: 1,
        //     withdrawAdjustment: 100000000
        // }));
        // tokens.push(TokenInfo({    //   MKR
        //     tokenAddress: 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
        //     priceOracleAddress: 0xec1D1B3b0443256cc3860e24a46F108e699484Aa,
        //     poolFee: 3000,
        //     priceAdjustment: 1,
        //     withdrawAdjustment: 100000000
        // }));
    }

    function buy(uint amount) external override{
        uint indexPrice = getPrice();
        (, uint realAmount) = calculateFee(amount);

        TransferHelper.safeTransferFrom(buyTokenAddress, msg.sender, address(this), amount);
        TransferHelper.safeApprove(buyTokenAddress, dexRouterAddress, realAmount);
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        for (uint256 index = 0; index < tokens.length; index++) {
            TokenInfo memory token = tokens[index];

            uint singleTokenAmount = realAmount / 100 * token.indexPercentage;

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: buyTokenAddress,
                tokenOut: token.tokenAddress,
                fee: token.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: singleTokenAmount,
                amountOutMinimum: (singleTokenAmount / token.priceAdjustment)
                    / priceOracle.getPrice(token.priceOracleAddress),
                sqrtPriceLimitX96: 0
            });

            dexRouter.exactInputSingle(params);
        }

        indexToken.transfer(msg.sender, realAmount / indexPrice);
    }

    function getPrice() public override view returns(uint){
        uint indexTotalPrice;

        for(uint i = 0; i < tokens.length; i++){
            TokenInfo memory token = tokens[i];
            uint price = priceOracle.getPrice(token.priceOracleAddress) * token.priceAdjustment;
            indexTotalPrice += (price * token.indexPercentage) / 100;
        }

        return indexTotalPrice * indexPriceAdjustment;
    }

    function sell(uint amount) external override checkUnlocked{

        require(amount > 1 ether, "You must withdraw more funds from the index");
        TransferHelper.safeTransferFrom(address(indexToken), msg.sender, address(this), amount);
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        for (uint256 index = 0; index < tokens.length; index++) {
            TokenInfo memory token = tokens[index];

            uint priceAdjustment = priceOracle.getPrice(token.priceOracleAddress) / token.withdrawAdjustment;
            uint tokenAmount = amount * 100 / token.indexPercentage * token.priceAdjustment / priceAdjustment;

            TransferHelper.safeApprove(token.tokenAddress, dexRouterAddress, tokenAmount);
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token.tokenAddress,
                tokenOut: buyTokenAddress,
                fee: token.poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: tokenAmount,
                amountOutMinimum: tokenAmount,
                sqrtPriceLimitX96: 0
            });

            dexRouter.exactInputSingle(params);
        }

    }

}
