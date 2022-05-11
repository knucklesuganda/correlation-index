// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract PriceOracle {
    using SafeMath for uint256;
    ISwapRouter private router;
    address _baseToken;

    constructor(ISwapRouter _router, address _baseToken){
        router = _router;
        baseToken = _baseToken;
    }

    function getPrice(address secondToken, address poolFee) external view returns (uint) {
        IUniswapV3Pool uniswapv3Pool = router.getPool(_baseToken, secondToken, poolFee);

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = 10000;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = uniswapv3Pool.observe(secondAgos);

        int56 tickCumulativesDiff = tickCumulatives[1] - tickCumulatives[0];
        uint56 period = uint56(secondAgos[0]-secondAgos[1]);

        int56 timeWeightedAverageTick = (tickCumulativesDiff / -int56(period));

        uint8 decimalToken0 =  IERC20Metadata(uniswapv3Pool.token0()).decimals();
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(timeWeightedAverageTick));
        uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
        price = uint32((ratioX192 * 1e18) >> (96 * 2));
        decimalAdjFactor = uint32(10**(decimalToken0));
        return price;

    }

}