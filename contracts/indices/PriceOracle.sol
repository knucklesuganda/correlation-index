// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract PriceOracle {
    using SafeMath for uint256;
    using SafeMath for uint160;

    IUniswapV3Factory private factory;

    constructor(address _factoryAddress){
        factory = IUniswapV3Factory(_factoryAddress);
    }

    function getLatestTick(address firstToken, address secondToken, uint24 fee) private view returns(int24){
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(firstToken, secondToken, fee));
        (, int24 tick, ,,,, ) = pool.slot0();
        return tick;
    }

    function getMinimalPoolLiquidity(address firstToken, address secondToken, uint24 fee) public view returns(uint){
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(firstToken, secondToken, fee));
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        uint priceQuarter = sqrtPriceX96.div(4);
        uint160 sqrtRatioBX96 = uint160(sqrtPriceX96.add(priceQuarter));
        uint160 sqrtRatioAX96 = uint160(sqrtPriceX96.sub(priceQuarter));

        (uint amount0, uint amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            pool.liquidity()
        );

        uint price = getPrice(firstToken, secondToken, [fee, 0], address(0));
        uint amount1InAmount0 = amount1.mul(price).div(1 ether);

        if(amount0 > amount1InAmount0){
            return amount1InAmount0;
        }else{
            return amount0;
        }
    }

    function getLiquidity(
        address firstToken, address secondToken, uint24[2] memory tokenFees, address intermediateToken
    ) external view returns(uint){
        if(intermediateToken == address(0)){
            return getMinimalPoolLiquidity(firstToken, secondToken, tokenFees[0]);
        }else{
            uint firstPoolLiquidity = getMinimalPoolLiquidity(firstToken, intermediateToken, tokenFees[0]);
            uint secondPoolLiquidity = getMinimalPoolLiquidity(intermediateToken, secondToken, tokenFees[1]);

            return firstPoolLiquidity > secondPoolLiquidity ? secondPoolLiquidity : firstPoolLiquidity;
        }

    }

    function getPrice(
        address firstToken, address secondToken, uint24[2] memory poolFees, address intermediateToken
    ) public view returns (uint) {

        if(intermediateToken == address(0)){
            int24 tick = getLatestTick(firstToken, secondToken, poolFees[0]);
            return OracleLibrary.getQuoteAtTick(tick, 1 ether, secondToken, firstToken);
        }else{
            int24 firstTick = getLatestTick(intermediateToken, secondToken, poolFees[1]);
            uint firstSwapPrice = OracleLibrary.getQuoteAtTick(firstTick, 1 ether, secondToken, intermediateToken);

            int24 secondTick = getLatestTick(firstToken, intermediateToken, poolFees[0]);
            uint secondSwapPrice = OracleLibrary.getQuoteAtTick(
                secondTick,
                uint128(firstSwapPrice),
                intermediateToken,
                firstToken
            );

            return secondSwapPrice;
        }

    }

}