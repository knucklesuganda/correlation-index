require("chai").use(require("chai-bignumber")(web3.BigNumber)).should();
const BN = require("bn.js");
const { assert } = require("chai");
const BaseIndex = artifacts.require("BaseIndex.sol");
const IERC20 = artifacts.require("IERC20");


contract('BaseIndex', (accounts) => {

    let buyToken;
    let indexToken;
    let testIndex;
    const account = process.env.ETH_WHALE;
    const indexOwner = accounts[0];
    let FUNDS_VALUE;

    beforeEach(async () => {
        testIndex = await BaseIndex.new();
        buyToken = await IERC20.at(await testIndex.buyTokenAddress());
        indexToken = await IERC20.at(await testIndex.indexToken());

        FUNDS_VALUE = new BN("100000000000000000000", 10);
        await buyToken.approve(await testIndex.address, FUNDS_VALUE, { from: account });
    });

    // it("should return index owner", async () => {
    //     const owner = await testIndex.owner();
    //     assert.equal(owner, indexOwner);
    // });

    it("must add funds according to the price", async () => {

        await testIndex.buy(FUNDS_VALUE, { from: account });
        const price = await testIndex.getPrice();

        console.log(FUNDS_VALUE.div(price).toString());

        assert.equal(
            await indexToken.balanceOf(account),
            FUNDS_VALUE.div(price)
        );

    });

    it("must add debt to the user", async () => {

        await testIndex.buy(FUNDS_VALUE, { from: account });
        const balance = await indexToken.balanceOf(account);

        indexToken.approve(testIndex.address, balance, { from: account });
        await testIndex.sell(balance, { from: account });

        assert.isAbove(
            await testIndex.usersDebt(account),
            0
        );

    });

    // it("should increase the balance of the index owner by fee", async () => {
    //     const balanceBefore = await buyToken.balanceOf(indexOwner);
    //     await testIndex.buy(FUNDS_VALUE, { from: account });
    //     const balanceAfter = await buyToken.balanceOf(indexOwner);
    // 
    //     console.log("Balance before: ", balanceBefore.toString(), " Balance after:", balanceAfter.toString());
    //     const fee = FUNDS_VALUE.div(100).mul(await testIndex.indexFee());
    //     assert.equal(balanceAfter.sub(balanceBefore).toString(), fee.toString());
    // });
    // 
    // it("should return the price of the index", async () => {
    //     const price = await testIndex.getPrice();
    //     console.log("Index price:", price.toString());
    // });
    // 
    // it("should be able to add funds to the index", async () => {
    //     console.log(await testIndex.buy(FUNDS_VALUE, { from: account }));
    //     console.log("Account index token balance:", (await indexToken.balanceOf(account)).toString());
    // });
    // 
    // it("should withdraw funds from the index", async () => {
    //     console.log(await testIndex.buy(FUNDS_VALUE, { from: account }));
    //     const tokenFunds = await indexToken.balanceOf(account);
    // 
    //     await indexToken.approve(await testIndex.address, tokenFunds, { from: account });
    // 
    //     /////////////////////////////////////////////////////////////////////////
    //     console.log(
    //         'ETH:', (await (
    //             await IERC20.at('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
    //         ).balanceOf(await testIndex.address)).toString(),
    // 
    //         '\n',
    // 
    //         'BTC:', (await (
    //             await IERC20.at('0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599')
    //         ).balanceOf(await testIndex.address)).toString()
    //     );
    //     /////////////////////////////////////////////////////////////////////////
    // 
    //     await testIndex.sell(tokenFunds, { from: account });
    //     console.log("Account DAI balance:", (await buyToken.balanceOf(account)).toString());
    // });

});
