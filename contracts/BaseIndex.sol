// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import './PriceOracle.sol';
import './IndexToken.sol';
import './DexConnector.sol';


contract BaseIndex {

    /// @notice TokenPrice shows you the returned price of any token in the index
    struct TokenPrice{
        address token;
        string name;
        uint256 price;
    }

    /// @notice TokenSwapPool is used in order to add tokens to the index
    /// @param tokenAddress - address of the token that we want to add
    /// @param poolFee - fee that will be paid to the pool of buyToken/tokenAddress
    /// @param priceOracleAddress - address of the priceOracle that will be used to get the price of the token
    struct TokenSwapPool{
        address tokenAddress;
        uint24 poolFee;
        address priceOracleAddress;
    }

    /// @notice IndexInitiailParameters is used to give the parameters to the index when it is created
    struct IndexInitialParameters{
        string tokenName;
        uint8 decimalUnits;
        uint initialAmount;
        string tokenSymbol;
        uint minimalFundAddition;
    }

    uint private totalUsedTokens;     // how many tokens were sent to the users
    IndexToken public immutable indexToken;     // IERC20 token that is used in the index
    uint256 public immutable minimalFundAddition;   // minimal amount of money you need to add to the index
    PriceOracle private immutable priceOracle = new PriceOracle();  // price oracle to get the price of the tokens
    BaseIndex.TokenSwapPool[] public tokenContracts;    // array of tokens that are used in the index
    address public immutable buyToken;
    DexConnector private immutable dexConnector;

    constructor(BaseIndex.IndexInitialParameters memory params, address uniswapAddress, address _buyToken){
        indexToken = new IndexToken(
            params.initialAmount, address(this), params.tokenName,
            params.decimalUnits, params.tokenSymbol
        );
        minimalFundAddition = params.minimalFundAddition;
        dexConnector = new DexConnector(uniswapAddress, address(this));
        buyToken = _buyToken;
    }

    /// @notice That function is used to buy the index tokens
    /// @dev I use Chainlink oracles in order to get the amount of the tokens, maybe need to use UniswapV3 Oracle
    /// @param amountIn uint - amount of money that we want to send to the index
    /// @return uint - amount of tokens that were bought
    function addFunds(uint amountIn) public returns(uint){
        require(amountIn >= minimalFundAddition, "Not enough funds to add to the index");

        uint buyAmount = amountIn / tokenContracts.length;
        uint tokensAmount = amountIn / getIndexPrice();

        require(
            indexToken.balanceOf(address(this)) >= tokensAmount,
            "Not enough tokens in the index, you can only buy it on secondary markets"
        );

        totalUsedTokens += tokensAmount;
        dexConnector.transferUserTokens(buyToken, msg.sender, amountIn);

        for (uint256 index = 0; index < tokenContracts.length; index++) {
            TokenSwapPool memory token = tokenContracts[index];
            uint tokenAmountOut = buyAmount / priceOracle.getPrice(token.priceOracleAddress);
            dexConnector.swap(buyToken, token.tokenAddress, token.poolFee, buyAmount, tokenAmountOut);
        }

        indexToken.transferFrom(address(this), msg.sender, tokensAmount);
        return tokensAmount;
    }

    function getIndexPrice() public view returns(uint){
        uint totalTokensPrice;

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            TokenSwapPool memory token = tokenContracts[i];
            totalTokensPrice += priceOracle.getPrice(token.priceOracleAddress);
        }

        return totalTokensPrice / tokenContracts.length;
    }

    function getTotalLockedValue() public view returns(uint){
        return totalUsedTokens * getIndexPrice();
    }

    function getMyTokensPrice() public view returns(uint){
        return indexToken.balanceOf(msg.sender) * getIndexPrice();
    }

}
