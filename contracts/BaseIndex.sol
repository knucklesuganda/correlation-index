// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

import "./PriceOracle.sol";
import "./IndexToken.sol";



contract BaseIndex is Ownable{
    address public immutable dexRouterAddress;
    address public immutable buyTokenAddress;

    struct TokenInfo{
        address tokenAddress;
        address priceOracleAddress;
        uint24 poolFee;
        uint priceAdjustment;
    }

    TokenInfo[] public tokens;
    PriceOracle private priceOracle;
    IndexToken public indexToken;
    uint private _indexFee;

    constructor(){
        dexRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;     // Uniswap V3 Router
        buyTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;     // DAI
        _indexFee = 1;
        indexToken = new IndexToken(address(this), 10000000, "Index token", 18, "INDEX");
        priceOracle = new PriceOracle();

        tokens.push(TokenInfo({     // WETH
            tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            priceOracleAddress: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            poolFee: 3000,
            priceAdjustment: 100000000
        }));
        tokens.push(TokenInfo({     // LINK
            tokenAddress: 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
            priceOracleAddress: 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9,
            poolFee: 3000,
            priceAdjustment: 100000000
        }));
        // tokens.push(TokenInfo({       // MATIC
        //     tokenAddress: 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,
        //     priceOracleAddress: 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676,
        //     poolFee: 3000
        // }));
    }

    function indexFee() external view returns(uint){
        return _indexFee;
    }

    function calculateFee(uint amount) private view returns(uint, uint){
        uint indexFeeAmount = (amount / 100) * _indexFee;
        uint realAmount = amount - indexFeeAmount;
        return (indexFeeAmount, realAmount);
    }

    function addFunds(uint amount) external{
        uint indexPrice = getIndexPrice();

        (uint fee, uint realAmount) = calculateFee(amount);
        require(realAmount / indexPrice > 0, "You must add more funds to the index");

        TransferHelper.safeTransferFrom(buyTokenAddress, msg.sender, address(this), amount);
        TransferHelper.safeApprove(buyTokenAddress, dexRouterAddress, realAmount);
        IERC20(buyTokenAddress).transfer(owner(), fee);
        uint totalTokens;

        uint singleTokenAmount = realAmount / tokens.length;
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        for (uint256 index = 0; index < tokens.length; index++) {            
            TokenInfo memory token = tokens[index];

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: buyTokenAddress,
                tokenOut: token.tokenAddress,
                fee: token.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: singleTokenAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            uint tokenOut = dexRouter.exactInputSingle(params);
            totalTokens += tokenOut;
        }

        indexToken.transfer(msg.sender, (totalTokens * 100000000) / indexPrice);
    }

    function getIndexPrice() public view returns(uint){
        uint indexTotalPrice;

        for(uint i = 0; i < tokens.length; i++){
            TokenInfo memory token = tokens[i];
            uint price = priceOracle.getPrice(token.priceOracleAddress, token.priceAdjustment);
            indexTotalPrice += price;
        }

        return indexTotalPrice / tokens.length;
    }

    function withdrawFunds(uint amount) external {
        require(amount > 1, "You must withdraw more funds from the index");
        (uint fee, uint realAmount) = calculateFee(amount);

        TransferHelper.safeTransferFrom(address(indexToken), msg.sender, address(this), amount);
        uint singleTokenAmount = realAmount / tokens.length;
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        for (uint256 index = 0; index < tokens.length; index++) {
            TokenInfo memory token = tokens[index];

            uint tokenPrice = priceOracle.getPrice(token.priceOracleAddress, token.priceAdjustment);
            uint tokenAmount = singleTokenAmount / tokenPrice;

            TransferHelper.safeApprove(token.tokenAddress, dexRouterAddress, tokenAmount);
            uint tokenBalance = IERC20(token.tokenAddress).balanceOf(address(this));

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token.tokenAddress,
                tokenOut: buyTokenAddress,
                fee: token.poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: tokenAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            dexRouter.exactInputSingle(params);
        }

    }

}
