require("chai").use(require("chai-bignumber")(web3.BigNumber)).should();
const BN = require("bn.js");
const { assert } = require("chai");
const Index = artifacts.require("Index.sol");
const IERC20 = artifacts.require("IERC20");


contract('Index', (accounts) => {

    let buyToken;
    let indexToken;
    let index;
    const account = process.env.ETH_WHALE;
    const indexOwner = accounts[0];
    let FUNDS_VALUE;

    beforeEach(async () => {
        index = await Index.new({ from: indexOwner });
        buyToken = await IERC20.at(await index.buyTokenAddress());
        indexToken = await IERC20.at(await index.indexToken());

        FUNDS_VALUE = new BN("1000000000000000000000", 10);     // 1000$
        await buyToken.approve(await index.address, FUNDS_VALUE, { from: account });
    });

    it("should return index owner", async () => {
        const foundOwner = await index.owner();
        console.log("Owner:", foundOwner);
        assert.equal(foundOwner, indexOwner, "owners are not the same");
    });

    const buyTokens = async () => {
        await buyToken.approve(index.address, FUNDS_VALUE, { from: account });

        const price = await index.getPrice();
        const tokensBought = FUNDS_VALUE.mul(new BN("1000000000000000000", 10)).div(price);

        console.log("Buying:", tokensBought.toString());

        await index.buy(tokensBought, { from: account });
        const feeData = await index.getFee();

        const fee = (100 / feeData[1].toNumber()) * feeData[0].toNumber();
        console.log("Fee:", fee);

        const value = FUNDS_VALUE.sub(
            FUNDS_VALUE.sub(
                FUNDS_VALUE.div(new BN('100', 10)).mul(new BN(fee, 10))
            )
        ).toString();

        assert.equal(
            (await buyToken.balanceOf(indexOwner)).toString(),
            "Fees were not sent to the index owner",
        );
        return [tokensBought, fee];
    };
    
    it("must add funds according to the price", async () => {
        const [tokensBought, fee] = await buyTokens();

        assert.equal(
            await index.getUserDebt(account, true),
            tokensBought.sub(tokensBought.div(new BN('100', 10)).mul(fee)),
            "Funds were not added according to the price",
        );

    });

    it("must settle the tokens", async () => {
        const [tokensBought, fee] = await buyTokens();

        const components = await index.getComponents();
        await index.beginSettlement({ from: indexOwner });

        for (const _ of components) {
            await index.manageTokens({ from: indexOwner });
        }
    
        await index.endSettlement({ from: indexOwner });

        const totalDebt = await index.getTotalDebt();
        const tenPercentDrawdown = tokensBought.sub(tokensBought.div(new BN('100', 10)).mul(new BN('10', 10)));

        assert.isAbove(totalDebt, tenPercentDrawdown, "Bought less that 10% of the tokens");
        let totalValue = 0;

        for (const component of components) {

            const token = await IERC20.at(component.tokenAddress);
            const tokenBalance = await token.balanceOf(address(this));
            const tokenUsdBalance = tokenBalance.mul(index.getTokenPrice(tokenInfo));
            totalValue = totalValue.add(tokenUsdBalance.div(new BN('1000000000000000000', 10)));

        }

        const totalLockedValue = await index.getTotalLockedValue();
        assert.equal(totalValue, totalLockedValue, "Total locked values are not the same");
    });

    it("should return the price of the index", async () => {
        const price = await index.getPrice();
        console.log("Index price:", price.toString());
    });

    it("should withdraw funds from the index", async () => {
        const [tokensBought, _] = await buyTokens();


        indexToken.approve(index.address, tokensBought, { from: account });
        await index.sell(tokenFunds, { from: account });
        console.log("Account DAI balance:", (await buyToken.balanceOf(account)).toString());
    });

});
