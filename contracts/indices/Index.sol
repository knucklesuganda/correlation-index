// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "./PriceOracle.sol";
import "./IndexToken.sol";
import "./DebtManager.sol";
import "../management/BaseProduct.sol";


contract Index is Product {
    using SafeMath for uint256;

    struct TokenInfo {
        uint8 indexPercentage;
        address tokenAddress;
        uint24[2] poolFees;
        address intermediateToken;
    }

    TokenInfo[10] private tokens;
    IndexToken public immutable indexToken;

    address private immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private immutable dexRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    DebtManager private immutable sellDebtManager = new DebtManager();
    DebtManager private immutable buyDebtManager = new DebtManager();
    PriceOracle private immutable priceOracle = new PriceOracle();

    uint private lastManagedToken = 0;
    uint public tokensToSell = 0;
    uint public tokensToBuy = 0;
    uint private tokensSold = 0;
    uint private buyAmountRequired = 0;
    bool private allTokensManaged = false;
    bool public cancellationActive = false;
    uint public availableTokens = 1500000000000000000000;

    function name() external pure override returns (string memory) { return "Index"; }
    function symbol() external pure override returns (string memory) { return "VID"; }
    function getComponents() external view returns (TokenInfo[10] memory) { return tokens; }

    function shortDescription() external pure override returns (string memory) {
        return "Void Index - fully decentralized index";
    }

    function longDescription() external pure override returns (string memory) {
        return "Void Index - fully decentralized index. It features 10 ERC20 tokens, and allows you to buy or sell them at once. You receive VID tokens as a proof of funds ownership";
    }

    function getTokenPrice(TokenInfo memory token) public view returns (uint256) {
        return priceOracle.getPrice(buyTokenAddress, token.tokenAddress, token.poolFees, token.intermediateToken);
    }

    function image() external pure override returns (string memory) {
        return "https://voidmanagementstorage.blob.core.windows.net/assets/logo_index.png";
    }

    function getTotalLockedValue() external view override returns (uint256) {
        uint totalValue;

        for (uint i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            totalValue = totalValue.add(
                IERC20(tokenInfo.tokenAddress).balanceOf(address(this)).mul(getTokenPrice(tokenInfo))
            );
        }

        return totalValue.div(1 ether);
    }

    function getAvailableLiquidity() public view returns(uint){
        uint minLiquidity;

        for(uint i = 0; i < tokens.length; i++){

            TokenInfo memory token = tokens[i];
            uint poolLiquidity = priceOracle.getLiquidity(
                buyTokenAddress,
                token.tokenAddress,
                token.poolFees,
                token.intermediateToken
            );

            if(poolLiquidity < minLiquidity || minLiquidity == 0){
                minLiquidity = poolLiquidity;
            }
        }

        minLiquidity = minLiquidity.mul(1 ether).div(getPrice());
        return minLiquidity;
    }

    constructor() {
        indexToken = new IndexToken(address(this), availableTokens);

        tokens[0] = TokenInfo({ // 0) WETH
            tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: address(0),
            indexPercentage: 25
        });
        tokens[1] = TokenInfo({ // 1) LINK
            tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 15
        });
        tokens[2] = TokenInfo({ // 3) UNI
            tokenAddress: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 20
        });
        tokens[3] = TokenInfo({ // 4) 1INCH
            tokenAddress: 0x111111111117dC0aa78b770fA6A738034120C302,
            poolFees: [uint24(3000), 10000],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 10
        });
        tokens[4] = TokenInfo({ // 5) SNX
            tokenAddress: 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
            poolFees: [uint24(3000), 10000],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 5
        });
        tokens[5] = TokenInfo({ // 7) COMP
            tokenAddress: 0xc00e94Cb662C3520282E6f5717214004A7f26888,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 5
        });
        tokens[6] = TokenInfo({ // 8) MKR
            tokenAddress: 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 3
        });
        tokens[7] = TokenInfo({ // 10) APE
            tokenAddress: 0x4d224452801ACEd8B2F0aebE155379bb5D594381,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 7
        });
        tokens[8] = TokenInfo({ // 13) AAVE
            tokenAddress: 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 5
        });
        tokens[9] = TokenInfo({ // 14) MATIC
            tokenAddress: 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            indexPercentage: 5
        });
        // tokens[2] = TokenInfo({ // 2) WBNB
        //     tokenAddress: 0x418D75f65a02b3D53B2418FB8E1fe493759c7605,
        //     poolFees: [uint24(3000), uint24(3000)],
        //     intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        //     indexPercentage: 10
        // });
        // tokens[6] = TokenInfo({ // 6) YFI
        //     tokenAddress: 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
        //     poolFees: [uint24(3000), uint24(3000)],
        //     intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        //     indexPercentage: 2
        // });
        // tokens[9] = TokenInfo({ // 9) SUSHI
        //     tokenAddress: 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2,
        //     poolFees: [uint24(3000), uint24(3000)],
        //     intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        //     indexPercentage: 8
        // });
        // tokens[11] = TokenInfo({ // 11) CRV
        //     tokenAddress: 0xD533a949740bb3306d119CC777fa900bA034cd52,
        //     poolFees: [uint24(3000), 10000],
        //     intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        //     indexPercentage: 5
        // });
        // tokens[12] = TokenInfo({ // 12) LOOKS
        //     tokenAddress: 0xf4d2888d29D722226FafA5d9B24F9164c092421E,
        //     poolFees: [uint24(3000), uint24(3000)],
        //     intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        //     indexPercentage: 2
        // });
        // tokens[15] = TokenInfo({ // 14) FTX
        //     tokenAddress: 0x50D1c9771902476076eCFc8B2A83Ad6b9355a4c9,
        //     poolFees: [uint24(3000), uint24(3000)],
        //     intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        //     indexPercentage: 5
        // });
        // tokens[16] = TokenInfo({ // 15) GNOSIS
        //     tokenAddress: 0x6810e776880C02933D47DB1b9fc05908e5386b96,
        //     poolFees: [uint24(3000), uint24(3000)],
        //     intermediateToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        //     indexPercentage: 3
        // });
    }

    function buy(uint256 amount) external override nonReentrant checkSettlement {
        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount > 0 && productFee > 0, "Not enough tokens sent");

        uint availableLiquidity = getAvailableLiquidity();
        require(
            availableLiquidity >= amount &&
            realAmount <= availableTokens &&
            tokensToBuy.add(tokensToSell) < availableLiquidity,
            "Not enough liquidity"
        );

        availableTokens = availableTokens.sub(realAmount);

        uint256 indexPrice = getPrice();
        uint buyTokenAmount = realAmount.mul(indexPrice).div(1 ether);

        tokensToBuy = tokensToBuy.add(buyTokenAmount);
        buyDebtManager.changeDebt(msg.sender, realAmount, true);

        TransferHelper.safeTransferFrom(buyTokenAddress, msg.sender, address(this), amount.mul(indexPrice).div(1 ether));
        TransferHelper.safeTransferFrom(
            buyTokenAddress, address(this), owner(),
            productFee.mul(indexPrice).div(1300000000000000000)
        );

        emit ProductBought(msg.sender, buyTokenAmount, realAmount);
    }

    function changeCancellation() external onlyOwner{ cancellationActive = !cancellationActive; }

    function cancelDebt(uint amount) external nonReentrant {
        require(cancellationActive, "Cancellation is not active");

        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount > 0 && productFee > 0, "Not enough tokens sent");

        availableTokens = availableTokens.add(realAmount);

        uint256 indexPrice = getPrice();
        uint buyTokenAmount = realAmount.mul(indexPrice).div(1 ether);

        tokensToBuy = tokensToBuy.sub(buyTokenAmount);
        buyDebtManager.changeDebt(msg.sender, realAmount, false);

        TransferHelper.safeTransfer(buyTokenAddress, msg.sender, amount.mul(indexPrice).div(1 ether));
        TransferHelper.safeTransfer(buyTokenAddress, owner(), productFee.mul(indexPrice).div(1300000000000000000));
    }

    function sell(uint amount) external override nonReentrant checkSettlement{
        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount > 0 && productFee > 0, "You must sell more tokens");

        uint availableLiquidity = getAvailableLiquidity();
        require(
            availableLiquidity >= amount &&
            tokensToBuy.add(tokensToSell) < availableLiquidity,
            "Not enough liquidity"
        );

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
        require(allTokensManaged, "Not all tokens were managed");
        buyDebtManager.changeTotalDebt(tokensToBuy.mul(1 ether).div(getPrice()), true);
        sellDebtManager.changeTotalDebt(tokensSold, true);

        if (buyAmountRequired < tokensToBuy) {
            TransferHelper.safeTransfer(buyTokenAddress, owner(), tokensToBuy.sub(buyAmountRequired));
        }

        tokensToBuy = 0;
        allTokensManaged = false;
        buyAmountRequired = 0;
        tokensToSell = 0;
        tokensSold = 0;
        isSettlement = false;
    }

    function manageTokensSell(TokenInfo memory token, ISwapRouter dexRouter, uint amount, uint tokenPrice) private {
        uint amountIn = amount.mul(getPrice()).mul(token.indexPercentage).div(100).div(tokenPrice);

        uint usdAmountIn = amountIn.mul(tokenPrice).div(1 ether);
        uint amountOutMinimum = usdAmountIn.sub(usdAmountIn.mul(productFee).mul(10).div(productFeeTotal));

        TransferHelper.safeApprove(token.tokenAddress, dexRouterAddress, amountIn);

        if(token.intermediateToken == address(0)){
            tokensSold = tokensSold.add(dexRouter.exactInputSingle(
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
            ));
        }else{
            tokensSold = tokensSold.add(dexRouter.exactInput(
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
            ));
        }
    }

    function manageTokensBuy(TokenInfo memory token, ISwapRouter dexRouter, uint amount, uint tokenPrice) private {
        uint amountOut = amount.mul(1 ether).div(tokenPrice);
        uint amountInMaximum = amount.add(amount.mul(productFee).mul(10).div(productFeeTotal));

        if(token.intermediateToken == address(0)){
            buyAmountRequired = buyAmountRequired.add(dexRouter.exactOutputSingle(
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
            ));
        }else{
            buyAmountRequired = buyAmountRequired.add(dexRouter.exactOutput(
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
            ));
        }
    }

    function manageTokens() external onlyOwner {
        require(!allTokensManaged, "Tokens are already managed or another management transaction is active");

        lastManagedToken += 1;
        if(lastManagedToken > tokens.length - 1){
            lastManagedToken = 0;
            allTokensManaged = true;
        }

        TokenInfo memory token = tokens[lastManagedToken];
        uint tokensToBuyAmount = tokensToBuy.mul(token.indexPercentage).div(100);
        uint tokenPrice = getTokenPrice(token);
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        if(tokensToBuyAmount > 0){ manageTokensBuy(token, dexRouter, tokensToBuyAmount, tokenPrice); }
        if(tokensToSell > 0){ manageTokensSell(token, dexRouter, tokensToSell, tokenPrice); }
    }

    function getPrice() public view override returns (uint) {
        uint indexTotalPrice = 0;

        for (uint i = 0; i < tokens.length; i++) {
            indexTotalPrice = indexTotalPrice.add(getTokenPrice(tokens[i]).mul(tokens[i].indexPercentage));
        }

        return indexTotalPrice.div(1000);
    }

}
