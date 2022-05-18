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
        address priceOracleAddress;
        uint24[2] poolFees;
        address intermediateToken;
    }

    TokenInfo[] public tokens;
    IndexToken public indexToken;

    address public WETH;
    address private immutable dexRouterAddress;

    DebtManager private sellDebtManager = new DebtManager();
    DebtManager private buyDebtManager = new DebtManager();
    PriceOracle private priceOracle = new PriceOracle();

    uint public lastManagedToken = 0;   // TODO: change the visibility
    uint public tokensToSell;    // index tokens that will be sold
    uint public tokensToBuy;    // usd tokens that will be bought

    function name() external pure override returns (string memory) { return "CryptoIndex"; }
    function symbol() external pure override returns (string memory) { return "CRYPTIX"; }
    function getComponents() external view returns (TokenInfo[] memory) { return tokens; }

    function shortDescription() external pure override returns (string memory) {
        return "Correlation index is a tool that allows you to diversify your investments";
    }

    function longDescription() external pure override returns (string memory) {
        return "Correlation index is a tool that allows you to diversify your investments";
    }

    function getTokenPrice(TokenInfo memory token) external view returns (uint256) {
        return priceOracle.getPrice(token.priceOracleAddress);
    }

    function image() external pure override returns (string memory) {
        return "https://cryptologos.cc/logos/polymath-network-poly-logo.png?v=022";
    }

    function getTotalLockedValue() external view override returns (uint256) {
        uint totalValue;

        for (uint i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            IERC20 token = IERC20(tokenInfo.tokenAddress);

            uint tokenBalance = token.balanceOf(address(this)).mul(
                priceOracle.getPrice(tokenInfo.priceOracleAddress)
            );
            totalValue = totalValue.add(tokenBalance.div(1 ether));
        }

        return totalValue;
    }

    constructor() {
        dexRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;  // Uniswap V3 Router
        buyTokenAddress =  0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        productFee = 10;
        productFeeTotal = 100;
        indexPriceAdjustment = 100;

        indexToken = new IndexToken(address(this), "Crypto index token", 18, "CRYPTIX");
        isLocked = false;

        tokens.push(TokenInfo({ // 0) WETH
            tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            priceOracleAddress: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: address(0),
            indexPercentage: 15
        }));
        tokens.push(TokenInfo({ // 1) LINK
            tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            priceOracleAddress: 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 2) WBNB
            tokenAddress: 0x418D75f65a02b3D53B2418FB8E1fe493759c7605,
            priceOracleAddress: 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 3) UNI
            tokenAddress: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
            priceOracleAddress: 0x553303d460EE0afB37EdFf9bE42922D8FF63220e,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ // 4) 1INCH
            tokenAddress: 0x111111111117dC0aa78b770fA6A738034120C302,
            priceOracleAddress: 0xc929ad75B72593967DE83E7F7Cda0493458261D9,
            poolFees: [uint24(3000), 10000],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 5) SNX
            tokenAddress: 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
            priceOracleAddress: 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699,
            poolFees: [uint24(3000), 10000],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 6) YFI
            tokenAddress: 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
            priceOracleAddress: 0xA027702dbb89fbd58938e4324ac03B58d812b0E1,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 7) COMP
            tokenAddress: 0xc00e94Cb662C3520282E6f5717214004A7f26888,
            priceOracleAddress: 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 8) MKR
            tokenAddress: 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
            priceOracleAddress: 0xec1D1B3b0443256cc3860e24a46F108e699484Aa,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // 9) SUSHI
            tokenAddress: 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2,
            priceOracleAddress: 0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ // 10) APE
            tokenAddress: 0x4d224452801ACEd8B2F0aebE155379bb5D594381,
            priceOracleAddress: 0xD10aBbC76679a20055E167BB80A24ac851b37056,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ // 11) CRV
            tokenAddress: 0xD533a949740bb3306d119CC777fa900bA034cd52,
            priceOracleAddress: 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f,
            poolFees: [uint24(3000), 10000],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
    }

    function buy(uint256 amount) external override nonReentrant checkSettlement {
        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount >= 1, "Not enough tokens sent");

        uint256 indexPrice = getPrice();
        uint buyTokenAmount = realAmount.mul(indexPrice).div(1 ether);
        tokensToBuy = tokensToBuy.add(buyTokenAmount);
        buyDebtManager.changeDebt(msg.sender, realAmount, true);

        TransferHelper.safeTransferFrom(buyTokenAddress, msg.sender, address(this), amount.mul(indexPrice).div(1 ether));
        IERC20(buyTokenAddress).transfer(owner(), productFee.mul(indexPrice).div(1 ether));

        emit ProductBought(msg.sender, buyTokenAmount, realAmount);
    }

    function sell(uint amount) external override nonReentrant checkSettlement checkUnlocked {
        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount >= 1, "You must sell more tokens");

        tokensToSell = tokensToSell.add(amount);
        sellDebtManager.changeDebt(msg.sender, realAmount, true);
        sellDebtManager.changeDebt(owner(), productFee, true);

        TransferHelper.safeTransferFrom(address(indexToken), msg.sender, address(this), amount);
        emit ProductSold(msg.sender, realAmount.mul(getPrice()), realAmount);
    }

    function retrieveDebt(uint amount, bool isBuyDebt) external nonReentrant checkSettlement checkUnlocked{
        DebtManager manager = isBuyDebt ? buyDebtManager : sellDebtManager;
        require(manager.getTotalDebt() >= amount && manager.getUserDebt(msg.sender) >= amount, "Not enough debt");

        ERC20(isBuyDebt ? address(indexToken) : buyTokenAddress).transfer(msg.sender, amount);
        manager.changeDebt(msg.sender, amount, false);
    }

    function getTotalDebt(bool isBuy) external view returns (uint) {
        if(isBuy){
            return buyDebtManager.getTotalDebt();
        }else{
            return sellDebtManager.getTotalDebt();
        }
    }

    function getUserDebt(address user, bool isBuy) external view returns (uint) {
        if(isBuy){
            return buyDebtManager.getUserDebt(user);
        }else{
            return sellDebtManager.getUserDebt(user);
        }
    }

    function beginSettlement() override external onlyOwner{
        isSettlement = true;
        TransferHelper.safeApprove(buyTokenAddress, dexRouterAddress, tokensToBuy);
        TransferHelper.safeApprove(address(indexToken), dexRouterAddress, tokensToSell);
    }

    function endSettlement() override external onlyOwner {
        buyDebtManager.changeTotalDebt(tokensToBuy.mul(1 ether).div(getPrice()), true);
        sellDebtManager.changeTotalDebt(tokensToSell, true);
        tokensToBuy = 0;
        tokensToSell = 0;
        isSettlement = false;
    }

    function manageTokensSell(TokenInfo memory token, uint amount, uint tokenPrice) private {
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);
        uint amountOut = amount.mul(1 ether).div(tokenPrice);
        uint amountInMaximum = amount.add(amount.mul(10).div(100));

        if(token.intermediateToken == address(0)){
            dexRouter.exactOutputSingle(
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
            dexRouter.exactOutput(
                ISwapRouter.ExactOutputParams({
                    path: abi.encodePacked(
                        buyTokenAddress,
                        token.poolFees[0],
                        token.intermediateToken,
                        token.poolFees[1],
                        token.tokenAddress
                    ),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: amountInMaximum
                })
            );
        }

    }

    function manageTokensBuy(TokenInfo memory token, uint amount, uint tokenPrice) private {
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);
        uint amountOut = amount.mul(1 ether).div(tokenPrice);
        uint amountInMaximum = amount.add(amount.mul(10).div(100));

        if(token.intermediateToken == address(0)){
            dexRouter.exactOutputSingle(
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
            dexRouter.exactOutput(
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
    }

    function manageTokens() external onlyOwner {
        lastManagedToken += 1;
        if(lastManagedToken > tokens.length - 1){ lastManagedToken = 0; }

        TokenInfo memory token = tokens[lastManagedToken];
        uint tokensToBuyAmount = tokensToBuy.div(100).mul(token.indexPercentage);
        uint tokensToSellAmount = tokensToSell.div(100).mul(token.indexPercentage);
        uint tokenPrice = priceOracle.getPrice(token.priceOracleAddress);

        if(tokensToBuyAmount > 0){ manageTokensBuy(token, tokensToBuyAmount, tokenPrice); }
        if(tokensToSellAmount > 0){ manageTokensSell(token, tokensToSellAmount, tokenPrice); }
    }

    function getPrice() public view override returns (uint256) {
        uint256 indexTotalPrice;

        for (uint256 i = 0; i < tokens.length; i++) {
            TokenInfo memory token = tokens[i];
            indexTotalPrice = indexTotalPrice.add(
                priceOracle.getPrice(token.priceOracleAddress).mul(token.indexPercentage).div(100)
            );
        }

        return indexTotalPrice.div(indexPriceAdjustment);
    }

}
