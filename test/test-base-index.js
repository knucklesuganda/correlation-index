require("chai").use(require("chai-bignumber")(web3.BigNumber)).should();
const BN = require("bn.js");
const CorrelationIndex = artifacts.require("CorrelationIndex");
const IERC20 = artifacts.require("IERC20");


contract('CorrelationIndex', (accounts) => {

    let buyToken;
    let indexToken;
    let testIndex;
    const account = process.env.ETH_WHALE;
    const indexOwner = accounts[0];
    const FUNDS_VALUE = 1000000;

    beforeEach(async () => {
        testIndex = await CorrelationIndex.new({ from: indexOwner });
        buyToken = await IERC20.at(await testIndex.buyTokenAddress());

        const indexTokenAddress = await testIndex.indexToken();
        indexToken = await IERC20.at(indexTokenAddress);

        await buyToken.approve(await testIndex.address, FUNDS_VALUE, { from: account });
    });
    /*
        it("should return index owner", async () => {
            const owner = await testIndex.owner();
            assert.equal(owner, indexOwner);
        });
    
        it("should increase the balance of the index owner by fee", async () => {
            const balanceBefore = await buyToken.balanceOf(indexOwner);
            await testIndex.addFunds(FUNDS_VALUE, { from: account });
            const balanceAfter = await buyToken.balanceOf(indexOwner);
    
            console.log("Balance before: ", balanceBefore.toNumber(), " Balance after:", balanceAfter.toNumber());
    
            const fee = (FUNDS_VALUE / 100) * (await testIndex.indexFee()).toNumber();
            assert.equal(balanceAfter.sub(balanceBefore).toNumber(), fee);
        });
    
        it("should return the price of the index", async () => {
            const price = await testIndex.getIndexPrice();
            console.log("Index price:", price.toString());
        });
    */

    it("should be able to add funds to the index", async () => {
        let initialBalance = parseFloat((await buyToken.balanceOf(account)).toString());
        await testIndex.addFunds(FUNDS_VALUE, { from: account, gas: 10000000 });
        console.log("Account index token balance:", (await indexToken.balanceOf(account)).toString());
    });

    it("should withdraw funds from the index", async () => {
        console.log(await testIndex.addFunds(FUNDS_VALUE, { from: account, gas: 10000000 }));
        const tokenFunds = (await indexToken.balanceOf(account)).toNumber();

        await indexToken.approve(await testIndex.address, tokenFunds, { from: account });

        /////////////////////////////////////////////////////////////////////////
        console.log(
            'ETH:', (await (
                await IERC20.at('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
            ).balanceOf(await testIndex.address)).toNumber()
        );
        console.log(
            'BTC:', (await (
                await IERC20.at('0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599')
            ).balanceOf(await testIndex.address)).toNumber()
        );
        /////////////////////////////////////////////////////////////////////////

        await testIndex.withdrawFunds(tokenFunds, { from: account, gas: 10000000 });
        console.log("Account DAI balance:", (await buyToken.balanceOf(account)).toString());
    });

});
