// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol';


contract BaseIndex {

    uint256 private totalFunds;
    mapping(address => uint256) private investors;
    uint256 public minimalFundAddition;

    string public name;
    string public symbol;

    address[] public priceConsumers;
    address[] public tokenContracts;

    uint24 public constant poolFee = 3000;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    ISwapRouter private constant uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    function getPrice() public view returns (uint) {
        uint totalPrice = 0;

        for (uint index = 0; index < priceConsumers.length; index++) {
            totalPrice += index;
        }

        return totalPrice / priceConsumers.length;
    }

    function addFunds() public payable {
        require(msg.value > minimalFundAddition, "Not enough funds to add to the index");
        totalFunds += msg.value;
        investors[msg.sender] += 1; //msg.value / getPrice();

        uint _amountIn = msg.value;
        address token = tokenContracts[1];

        // TransferHelper.safeTransferFrom(WETH, msg.sender, address(this), _amountIn);
        // TransferHelper.safeApprove(WETH, address(uniswapRouter), _amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: token,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0,    // TODO: that should be a real amount from the oracles
            sqrtPriceLimitX96: 0
        });

        uniswapRouter.exactInputSingle{ value: msg.value }(params);
    }

    receive() payable external {}

    function getTVL() public view returns(uint256){
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
        minimalFundAddition = 100;
        name = "Correlation Index";
        symbol = "CI";

        priceConsumers = [
            // BSC mainnet
            // 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE,    // BNB
            // 0x7CA57b0cA6367191c94C8914d7Df09A57655905f,    // MATIC
            // 0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf,    // WBTC
            // 0xca236E327F629f9Fc2c30A4E95775EbF0B89fac8,    // LINK
            // 0xF4C5e535756D11994fCBB12Ba8adD0192D9b88be,    // TRX
            // 0xb57f259E7C24e56a1dA00F66b55A5640d9f9E7e4,    // UNI

            // ETH mainnet
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,    // ETH
            0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c,    // BTC
            0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c    // LINK
        ];

        tokenContracts = [
            // ETH mainnet
            // 0xB8c77482e45F1F44dE1745F52C74426C631bDD52,     // BNB
            // 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,     // MATIC
            // 0xE1Be5D3f34e89dE342Ee97E6e90D405884dA6c67,     // TRX
            // 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,     // UNI

            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,    // WETH
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,     // WBTC
            0x514910771AF9Ca656af840dff83E8264EcF986CA     // LINK
        ];
    }

}
