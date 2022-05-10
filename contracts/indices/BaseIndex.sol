// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

import "./PriceOracle.sol";
import "./IndexToken.sol";
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
    PriceOracle private priceOracle;
    IndexToken public indexToken;

    address public WETH;
    address private immutable dexRouterAddress;

    uint public lastManagedToken = 0;   // TODO: change the visibility
    uint public tokensToSell;    // index tokens that will be sold
    uint public tokensToBuy;    // usd tokens that will be bought
    uint public totalAvailableDebt;    // total debt for the index
    mapping(address => uint) public usersDebt;    // debt to each user

    event DebtRetrieved(address account, uint debtAmount);

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

            uint tokenBalance = token.balanceOf(address(this)).mul(priceOracle.getPrice(tokenInfo.priceOracleAddress));
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
        priceOracle = new PriceOracle();
        isLocked = false;

        tokens.push(TokenInfo({ // WETH
            tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            priceOracleAddress: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: address(0),
            indexPercentage: 15
        }));
        tokens.push(TokenInfo({ // LINK
            tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            priceOracleAddress: 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // WBNB
            tokenAddress: 0x418D75f65a02b3D53B2418FB8E1fe493759c7605,
            priceOracleAddress: 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({ // UNI
            tokenAddress: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
            priceOracleAddress: 0x553303d460EE0afB37EdFf9bE42922D8FF63220e,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({ //   1INCH
            tokenAddress: 0x111111111117dC0aa78b770fA6A738034120C302,
            priceOracleAddress: 0xc929ad75B72593967DE83E7F7Cda0493458261D9,
            poolFees: [uint24(3000), 10000],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({    //   SNX
            tokenAddress: 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
            priceOracleAddress: 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699,
            poolFees: [uint24(3000), 10000],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({    //   YFI
            tokenAddress: 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
            priceOracleAddress: 0xA027702dbb89fbd58938e4324ac03B58d812b0E1,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({    //   COMP
            tokenAddress: 0xc00e94Cb662C3520282E6f5717214004A7f26888,
            priceOracleAddress: 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({    //   MKR
            tokenAddress: 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
            priceOracleAddress: 0xec1D1B3b0443256cc3860e24a46F108e699484Aa,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        tokens.push(TokenInfo({    //   SUSHI
            tokenAddress: 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2,
            priceOracleAddress: 0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({    //   APE
            tokenAddress: 0x4d224452801ACEd8B2F0aebE155379bb5D594381,
            priceOracleAddress: 0xD10aBbC76679a20055E167BB80A24ac851b37056,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({    //   CRV
            tokenAddress: 0xD533a949740bb3306d119CC777fa900bA034cd52,
            priceOracleAddress: 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f,
            poolFees: [uint24(3000), 10000],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
        // tokens.push(TokenInfo({    //   Huobi Token
        //     tokenAddress: 0x6f259637dcD74C767781E37Bc6133cd6A68aa161,
        //     priceOracleAddress: 0xE1329B3f6513912CAf589659777b66011AEE5880,
        //     poolFees: [10000, uint24(3000)],
        //     intermediateToken: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        //     indexPercentage: 5
        // }));
        // tokens.push(TokenInfo({    //   BNT
        //     tokenAddress: 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C,
        //     priceOracleAddress: 0x1E6cF0D433de4FE882A437ABC654F58E1e78548c,
        //     poolFee: uint24(3000),
        //     indexPercentage: 5
        // }));
        tokens.push(TokenInfo({    //   INJ
            tokenAddress: 0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30,
            priceOracleAddress: 0xaE2EbE3c4D20cE13cE47cbb49b6d7ee631Cd816e,
            poolFees: [uint24(3000), uint24(3000)],
            intermediateToken: WETH,
            indexPercentage: 5
        }));
    }

    function buy(uint256 amount) external nonReentrant checkSettlement override {
        uint256 indexPrice = getPrice();
        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount >= 1, "Not enough tokens sent");

        uint buyTokenAmount = realAmount.mul(indexPrice).div(1 ether);
        tokensToBuy = tokensToBuy.add(buyTokenAmount);

        indexToken.transfer(msg.sender, realAmount);
        TransferHelper.safeTransferFrom(
            buyTokenAddress, msg.sender, address(this), amount.mul(indexPrice).div(1 ether)
        );

        IERC20 _buyToken = IERC20(buyTokenAddress);
        _buyToken.transfer(owner(), productFee.mul(indexPrice).div(1 ether));

        emit ProductBought(msg.sender, buyTokenAmount, realAmount);
    }

    function retrieveDebt(uint amount) external nonReentrant checkSettlement checkUnlocked{
        require(usersDebt[msg.sender].sub(amount) > 0, "Not enough debt, try selling your tokens first");
        
        usersDebt[msg.sender] = usersDebt[msg.sender].sub(amount);
        totalAvailableDebt = totalAvailableDebt.sub(amount);

        IERC20(buyTokenAddress).transfer(msg.sender, amount);
        emit DebtRetrieved(msg.sender, amount);
    }

    function sell(uint amount) external override nonReentrant checkSettlement checkUnlocked {
        (uint productFee, uint256 realAmount) = calculateFee(amount);
        require(realAmount >= 1, "You must sell more tokens");

        uint newUserDebt = realAmount.mul(getPrice()).div(1 ether);
        usersDebt[msg.sender] = usersDebt[msg.sender].add(newUserDebt);
        tokensToSell = realAmount.add(tokensToSell);

        TransferHelper.safeTransferFrom(address(indexToken), msg.sender, address(this), amount);
        indexToken.transfer(owner(), productFee);

        emit ProductSold(msg.sender, newUserDebt, realAmount);
    }

    function beginSettlement() override external onlyOwner{
        isSettlement = true;
        TransferHelper.safeApprove(buyTokenAddress, dexRouterAddress, tokensToBuy);
        TransferHelper.safeApprove(address(indexToken), dexRouterAddress, tokensToSell);
    }

    function endSettlement() override external onlyOwner {
        tokensToBuy = 0;
        tokensToSell = 0;
        isSettlement = false;
    }

    function manageTokensSell(TokenInfo memory token, uint amount, uint tokenPrice) private {
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);
        uint minOutAmount = amount.mul(tokenPrice).mul(1 ether);

        if(token.intermediateToken == address(0)){
            dexRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: buyTokenAddress,
                    tokenOut: token.tokenAddress,
                    fee: token.poolFees[0],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amount,
                    amountOutMinimum: minOutAmount,
                    sqrtPriceLimitX96: 0
                })
            );
        }else{
            totalAvailableDebt.add(dexRouter.exactInput(
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
                    amountIn: amount,
                    amountOutMinimum: minOutAmount
                })
            ));
        }
    }

    function manageTokensBuy(TokenInfo memory token, uint amount, uint tokenPrice) private {
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);
        uint minOutAmount = amount.div(tokenPrice).mul(1 ether);

        if(token.intermediateToken == address(0)){
            dexRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: buyTokenAddress,
                    tokenOut: token.tokenAddress,
                    fee: token.poolFees[0],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amount,
                    amountOutMinimum: minOutAmount,
                    sqrtPriceLimitX96: 0
                })
            );
        }else{
            dexRouter.exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        buyTokenAddress,
                        token.poolFees[0],
                        token.intermediateToken,
                        token.poolFees[1],
                        token.tokenAddress
                    ),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amount,
                    amountOutMinimum: minOutAmount
                })
            );
        }
    }

    function manageTokens() external onlyOwner {
        lastManagedToken += 1;
        if(lastManagedToken > tokens.length - 1){
            lastManagedToken = 0;
        }

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
                priceOracle.getPrice(token.priceOracleAddress).div(100).mul(token.indexPercentage)
            );
        }

        return indexTotalPrice.div(indexPriceAdjustment);
    }

}
