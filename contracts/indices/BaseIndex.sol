// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

import "./PriceOracle.sol";
import "./IndexToken.sol";
import "./DebtManager.sol";
import "../management/BaseProduct.sol";


contract BaseIndex is Product {
    using SafeMath for uint256;

    struct TokenInfo {
        uint8 indexPercentage;
        address tokenAddress;
        uint24[2] poolFees;
        address intermediateToken;
    }

    TokenInfo[] private tokens;
    IndexToken public immutable indexToken;

    address private immutable WETH;
    address private immutable dexRouterAddress;

    DebtManager private immutable sellDebtManager = new DebtManager();
    DebtManager private immutable buyDebtManager = new DebtManager();
    PriceOracle private immutable priceOracle;

    uint private lastManagedToken = 0;
    uint public tokensToSell = 0;
    uint public tokensToBuy = 0;
    uint private tokensSold = 0;
    uint private buyAmountRequired = 0;

    function name() external pure override returns (string memory) { return "Index"; }
    function symbol() external pure override returns (string memory) { return "VID"; }
    function getComponents() external view returns (TokenInfo[] memory) { return tokens; }

    function shortDescription() external pure override returns (string memory) {
        return "Void Index - diversify your investments.";
    }

    function longDescription() external pure override returns (string memory) {
        return "Void Index - diversify your investments. It features 20 tokens from Uniswap and allows you to buy all of them at once. You receive VID tokens as a proof of funds ownership";
    }

    function getTokenPrice(TokenInfo memory token) public view returns (uint256) {
        return priceOracle.getPrice(token.tokenAddress, token.poolFees, token.intermediateToken);
    }

    function image() external pure override returns (string memory) {
        return "https://cryptologos.cc/logos/polymath-network-poly-logo.png?v=022";
        // TODO: change image to public url
    }

    function getTotalLockedValue() external view override returns (uint256) {
        uint totalValue;

        for (uint i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            uint tokenUsdBalance = IERC20(tokenInfo.tokenAddress).balanceOf(address(this)).mul(getTokenPrice(tokenInfo));
            totalValue = totalValue.add(tokenUsdBalance.div(1 ether));
        }

        return totalValue;
    }

    constructor(
        address _dexRouterAddress,
        address _dexFactoryAddress,
        address _WETH,
        address _buyTokenAddress,
        string memory _indexTokenName,
        string memory _indexTokenSymbol
    ) {
        dexRouterAddress = _dexRouterAddress; // 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        buyTokenAddress = _buyTokenAddress; // 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        WETH = _WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        priceOracle = new PriceOracle(_dexFactoryAddress, _buyTokenAddress, _WETH);

        productFee = 2;
        productFeeTotal = 100;
        indexToken = new IndexToken(
            address(this),
            _indexTokenName,
            ERC20(buyTokenAddress).decimals(),
            _indexTokenSymbol
        );

        tokens.push(TokenInfo({ // 0) WETH
            tokenAddress: _WETH,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: address(0),
            indexPercentage: 15
        }));
        tokens.push(TokenInfo({ // 1) LINK
            tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: _WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 2) WBNB
            tokenAddress: 0x418D75f65a02b3D53B2418FB8E1fe493759c7605,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: _WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ // 3) UNI
            tokenAddress: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: _WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ // 4) 1INCH
            tokenAddress: 0x111111111117dC0aa78b770fA6A738034120C302,
            poolFees: [uint24(3000), 10000],
            intermediateToken: _WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ // 5) SNX
            tokenAddress: 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
            poolFees: [uint24(3000), 10000],
            intermediateToken: _WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 6) YFI
            tokenAddress: 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: _WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 7) COMP
            tokenAddress: 0xc00e94Cb662C3520282E6f5717214004A7f26888,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: _WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 8) MKR
            tokenAddress: 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: _WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 9) SUSHI
            tokenAddress: 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: _WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ // 10) APE
            tokenAddress: 0x4d224452801ACEd8B2F0aebE155379bb5D594381,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: _WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ // 11) CRV
            tokenAddress: 0xD533a949740bb3306d119CC777fa900bA034cd52,
            poolFees: [uint24(3000), 10000],
            intermediateToken: _WETH,
            indexPercentage: 10
        }));
    }

    function buy(uint256 amount) external override nonReentrant checkSettlement {
        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount > 0 && productFee > 0, "Not enough tokens sent");

        uint256 indexPrice = getPrice();
        uint buyTokenAmount = realAmount.mul(indexPrice).div(1 ether);

        tokensToBuy = tokensToBuy.add(buyTokenAmount);
        buyDebtManager.changeDebt(msg.sender, realAmount, true);

        TransferHelper.safeTransferFrom(buyTokenAddress, msg.sender, address(this), amount.mul(indexPrice).div(1 ether));
        TransferHelper.safeTransferFrom(buyTokenAddress, address(this), owner(), productFee.mul(indexPrice).div(2 ether));

        emit ProductBought(msg.sender, buyTokenAmount, realAmount);
    }

    function sell(uint amount) external override nonReentrant checkSettlement{
        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount > 0 && productFee > 0, "You must sell more tokens");

        uint indexPrice = getPrice();

        tokensToSell = tokensToSell.add(amount);
        sellDebtManager.changeDebt(msg.sender, realAmount.mul(indexPrice).div(1 ether), true);
        sellDebtManager.changeDebt(owner(), productFee.mul(indexPrice).div(1 ether), true);

        TransferHelper.safeTransferFrom(address(indexToken), msg.sender, address(this), amount);
        emit ProductSold(msg.sender, realAmount.mul(getPrice()), realAmount);
    }

    function retrieveDebt(uint amount, bool isBuyDebt) external nonReentrant checkSettlement{
        DebtManager manager = isBuyDebt ? buyDebtManager : sellDebtManager;
        require(manager.getTotalDebt() >= amount && manager.getUserDebt(msg.sender) >= amount, "Not enough debt");

        address token = isBuyDebt ? address(indexToken) : buyTokenAddress;

        TransferHelper.safeTransfer(token, msg.sender, amount);
        manager.changeDebt(msg.sender, amount, false);
        manager.changeTotalDebt(amount, false);
    }

    function getTotalDebt(bool isBuy) external view returns (uint) {
        return (isBuy ? buyDebtManager : sellDebtManager).getTotalDebt();
    }

    function getUserDebt(address user, bool isBuy) external view returns (uint) {
        return (isBuy ? buyDebtManager : sellDebtManager).getUserDebt(user);
    }

    function beginSettlement() override external onlyOwner{
        isSettlement = true;

        uint totalBuyFees = tokensToBuy.mul(productFee).div(productFeeTotal);
        TransferHelper.safeApprove(buyTokenAddress, dexRouterAddress, tokensToBuy.add(totalBuyFees));
    }

    function endSettlement() override external onlyOwner {
        buyDebtManager.changeTotalDebt(tokensToBuy.mul(1 ether).div(getPrice()), true);
        sellDebtManager.changeTotalDebt(tokensSold, true);

        if (buyAmountRequired < tokensToBuy && buyAmountRequired != 0) {
            TransferHelper.safeTransfer(buyTokenAddress, owner(), tokensToBuy.sub(buyAmountRequired));
        }

        tokensToBuy = 0;
        buyAmountRequired = 0;
        tokensToSell = 0;
        tokensSold = 0;
        isSettlement = false;
    }

    function getTokensDrawdown(uint amount) private view returns(uint){
        return amount.mul(productFee).mul(10).div(productFeeTotal);
    }

    function manageTokensSell(TokenInfo memory token, uint amount, uint tokenPrice) private {
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        uint tokenPercentage = amount.mul(getPrice()).mul(token.indexPercentage).div(100);
        uint amountIn = tokenPercentage.div(tokenPrice);

        uint usdAmountIn = amountIn.mul(tokenPrice).div(1 ether);
        uint amountOutMinimum = usdAmountIn.sub(getTokensDrawdown(usdAmountIn));

        uint amountOut;
        TransferHelper.safeApprove(token.tokenAddress, dexRouterAddress, amountIn);

        if(token.intermediateToken == address(0)){
            amountOut = dexRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: token.tokenAddress,
                    tokenOut: buyTokenAddress,
                    fee: token.poolFees[0],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMinimum,
                    sqrtPriceLimitX96: 0
                })
            );
        }else{
            amountOut = dexRouter.exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        token.tokenAddress,
                        token.poolFees[1],
                        token.intermediateToken,
                        token.poolFees[0],
                        buyTokenAddress
                    ),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMinimum
                })
            );
        }

        tokensSold = tokensSold.add(amountOut);
    }

    function manageTokensBuy(TokenInfo memory token, uint amount, uint tokenPrice) private {
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);
        uint amountOut = amount.mul(1 ether).div(tokenPrice);
        uint amountInMaximum = amount.add(getTokensDrawdown(amount));
        uint amountInRequired;

        if(token.intermediateToken == address(0)){
            amountInRequired = dexRouter.exactOutputSingle(
                ISwapRouter.ExactOutputSingleParams({
                    tokenIn: buyTokenAddress,
                    tokenOut: token.tokenAddress,
                    fee: token.poolFees[0],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: amountInMaximum,
                    sqrtPriceLimitX96: 0
                })
            );
        }else{
            amountInRequired = dexRouter.exactOutput(
                ISwapRouter.ExactOutputParams({
                    path: abi.encodePacked(
                        token.tokenAddress,
                        token.poolFees[1],
                        token.intermediateToken,
                        token.poolFees[0],
                        buyTokenAddress
                    ),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: amountInMaximum
                })
            );
        }

        buyAmountRequired = buyAmountRequired.add(amountInRequired);
    }

    function manageTokens() external onlyOwner {
        lastManagedToken += 1;
        if(lastManagedToken > tokens.length - 1){ lastManagedToken = 0; }

        TokenInfo memory token = tokens[lastManagedToken];
        uint tokensToBuyAmount = tokensToBuy.mul(token.indexPercentage).div(100);
        uint tokenPrice = getTokenPrice(token);

        if(tokensToBuyAmount > 0){
            manageTokensBuy(token, tokensToBuyAmount, tokenPrice);
        }
        if(tokensToSell > 0){
            manageTokensSell(token, tokensToSell, tokenPrice);
        }
    }

    function getPrice() public view override returns (uint) {
        uint indexTotalPrice = 0;

        for (uint i = 0; i < tokens.length; i++) {
            TokenInfo memory token = tokens[i];
            indexTotalPrice = indexTotalPrice.add(getTokenPrice(token).mul(token.indexPercentage).div(100));
        }

        return indexTotalPrice;
    }

}
