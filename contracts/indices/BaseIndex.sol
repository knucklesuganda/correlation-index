// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

import "./PriceOracle.sol";
import "./IndexToken.sol";
import "../management/BaseProduct.sol";

contract BaseIndex is Product {
    struct TokenInfo {
        uint8 indexPercentage;
        uint24 poolFee;
        address tokenAddress;
        address priceOracleAddress;
    }

    TokenInfo[] public tokens;
    PriceOracle private priceOracle;
    IndexToken public indexToken;
    address private immutable dexRouterAddress;
    uint public tokensToSell;
    uint public tokensToBuy;
    mapping(address => uint) public usersDebt;

    event DebtRetrieval(address account, uint debtAmount);

    function name() external pure override returns (string memory) {
        return "CryptoIndex";
    }

    function symbol() external pure override returns (string memory) {
        return "CRYPTIX";
    }

    function shortDescription() external pure override returns (string memory) {
        return "Correlation index is a tool that allows you to diversify your investments";
    }

    function longDescription() external pure override returns (string memory) {
        return "Correlation index is a tool that allows you to diversify your investments";
    }

    function getComponents() external view returns (TokenInfo[] memory) {
        return tokens;
    }

    function getTokenPrice(address tokenOracleAddress) external view returns (uint256) {
        return priceOracle.getPrice(tokenOracleAddress);
    }

    function image() external pure override returns (string memory) {
        return "https://cryptologos.cc/logos/polymath-network-poly-logo.png?v=022";
    }

    function getTotalLockedValue() external view override returns (uint256) {
        uint totalValue;

        for (uint i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            IERC20 token = IERC20(tokenInfo.tokenAddress);
            totalValue += token.balanceOf(address(this)) * priceOracle.getPrice(tokenInfo.priceOracleAddress);
        }

        return totalValue;
    }

    constructor() {
        dexRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // Uniswap V3 Router
        buyTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // USDC
        indexFee = 5;
        indexFeeTotal = 1000;
        indexPriceAdjustment = 100;
        indexToken = new IndexToken( address(this), "Crypto index token", 18, "CRYPTIX");
        priceOracle = new PriceOracle();
        isLocked = false;

        tokens.push(
            TokenInfo({ // WETH
                tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                priceOracleAddress: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
                poolFee: 3000,
                indexPercentage: 20
            })
        );
        tokens.push(
            TokenInfo({ // LINK
                tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
                priceOracleAddress: 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c,
                poolFee: 3000,
                indexPercentage: 10
            })
        );
        tokens.push(
            TokenInfo({ // BNB
                tokenAddress: 0x418D75f65a02b3D53B2418FB8E1fe493759c7605,
                priceOracleAddress: 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A,
                poolFee: 3000,
                indexPercentage: 20
            })
        );
        tokens.push(
            TokenInfo({ // UNI
                tokenAddress: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
                priceOracleAddress: 0x553303d460EE0afB37EdFf9bE42922D8FF63220e,
                poolFee: 3000,
                indexPercentage: 10
            })
        );
        tokens.push(
            TokenInfo({ //   1INCH
                tokenAddress: 0x111111111117dC0aa78b770fA6A738034120C302,
                priceOracleAddress: 0xc929ad75B72593967DE83E7F7Cda0493458261D9,
                poolFee: 3000,
                indexPercentage: 10
            })
        );
        tokens.push(TokenInfo({    //   SNX
            tokenAddress: 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
            priceOracleAddress: 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699,
            poolFee: 3000,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({    //   YFI
            tokenAddress: 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
            priceOracleAddress: 0xA027702dbb89fbd58938e4324ac03B58d812b0E1,
            poolFee: 3000,
            indexPercentage: 10
        }));
        tokens.push(TokenInfo({    //   COMP
            tokenAddress: 0xc00e94Cb662C3520282E6f5717214004A7f26888,
            priceOracleAddress: 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5,
            poolFee: 3000,
            indexPercentage: 5  
        }));
        tokens.push(TokenInfo({    //   MKR
            tokenAddress: 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
            priceOracleAddress: 0xec1D1B3b0443256cc3860e24a46F108e699484Aa,
            poolFee: 3000,
            indexPercentage: 5
        }));
    }

    function buy(uint256 amount) external override {
        uint256 indexPrice = getPrice();
        (, uint256 realAmount) = calculateFee(amount);
        tokensToBuy += realAmount;

        uint256 indexTokens = (realAmount / indexPrice) * 1 ether;
        require(indexTokens > 0, "Not enough tokens sent");

        TransferHelper.safeTransferFrom(buyTokenAddress, msg.sender, address(this), amount);
        indexToken.transfer(msg.sender, indexTokens);
        emit ProductBuy(msg.sender, realAmount, indexTokens);
    }

    function retrieveDebt(uint amount) external checkUnlocked{
        require(usersDebt[msg.sender] - amount > 0, "Not enough debt, try selling your tokens first");
        
        usersDebt[msg.sender] -= amount;
        IERC20(buyTokenAddress).transfer(msg.sender, amount);
        emit DebtRetrieval(msg.sender, amount);
    }

    function sell(uint amount) external override checkUnlocked {
        require(amount >= 1 ether, "You must sell more tokens");
        TransferHelper.safeTransferFrom(address(indexToken), msg.sender, address(this), amount);

        uint indexPrice = getPrice();
        tokensToSell += amount;
        usersDebt[msg.sender] += (amount * indexPrice) / 1 ether;
        emit ProductSell(msg.sender, amount * indexPrice, amount);

    }

    function findToken(address tokenAddress) private view returns(TokenInfo memory){
        for (uint256 index = 0; index < tokens.length; index++) {
            TokenInfo memory token = tokens[index];

            if (token.tokenAddress == tokenAddress) {
                return token;
            }
        }

        revert("No such token");
    }

    function buyToken(address tokenAddress) external onlyOwner {
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        TokenInfo memory token = findToken(tokenAddress);
        uint256 tokenAmount = (tokensToBuy / 100) * token.indexPercentage;
        tokensToBuy -= tokenAmount;

        dexRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: buyTokenAddress,
                tokenOut: token.tokenAddress,
                fee: token.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: tokenAmount,
                amountOutMinimum: tokenAmount / priceOracle.getPrice(token.priceOracleAddress),
                sqrtPriceLimitX96: 0
            })
        );

    }

    function sellToken(address tokenAddress) external onlyOwner {
        ISwapRouter dexRouter = ISwapRouter(dexRouterAddress);

        TokenInfo memory token = findToken(tokenAddress);
        uint256 tokenAmount = (tokensToSell / 100) * token.indexPercentage;
        tokensToSell -= tokenAmount;

        TransferHelper.safeApprove(token.tokenAddress, dexRouterAddress, tokenAmount);
        dexRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token.tokenAddress,
                tokenOut: buyTokenAddress,
                fee: token.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: tokenAmount,
                amountOutMinimum: tokenAmount / priceOracle.getPrice(token.priceOracleAddress),
                sqrtPriceLimitX96: 0
            })
        );
    }

    function getPrice() public view override returns (uint256) {
        uint256 indexTotalPrice;

        for (uint256 i = 0; i < tokens.length; i++) {
            TokenInfo memory token = tokens[i];
            uint256 price = priceOracle.getPrice(token.priceOracleAddress);
            indexTotalPrice += (price / 100) * token.indexPercentage;
        }

        return indexTotalPrice / indexPriceAdjustment;
    }

}
