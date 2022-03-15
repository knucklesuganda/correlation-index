// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol';

contract DexConnector {
    ISwapRouter private immutable uniswapRouter;    // Uniswap router that we use to swap tokens
    address private indexAddress;

    constructor(address _dexAddress, address _indexAddress){
        uniswapRouter = ISwapRouter(_dexAddress);
        indexAddress = _indexAddress;
    }

    function transferUserTokens(address token, address _user, uint _amount) public {
        // TransferHelper.safeTransferFrom(buyToken, msg.sender, address(this), amountIn);
        // TransferHelper.safeApprove(buyToken, address(uniswapRouter), amountIn);
        IERC20(token).transferFrom(_user, indexAddress, _amount);
        IERC20(token).approve(address(uniswapRouter), _amount);
    }

    function swap(
        address fromToken, address toToken, uint24 poolFee, uint buyAmount, uint amountOut
    ) public{
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: fromToken,
            tokenOut: toToken,
            fee: poolFee,
            recipient: indexAddress,
            deadline: block.timestamp,
            amountIn: buyAmount,
            amountOutMinimum: amountOut,
            sqrtPriceLimitX96: 0
        });

        uniswapRouter.exactInputSingle(params);
    }
}
