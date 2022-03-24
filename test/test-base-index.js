require("chai").use(require("chai-bignumber")(web3.BigNumber)).should();
const BN = require("bn.js");
const CorrelationIndex = artifacts.require("CorrelationIndex");
const IERC20 = artifacts.require("IERC20");


contract('CorrelationIndex', (accounts) => {

    let buyToken;
    let indexToken;
    let testIndex;
    const account = process.env.ETH_WHALE;
    const FUNDS_VALUE = 1000000;

    beforeEach(async () => {
        testIndex = await CorrelationIndex.new();
        buyToken = await IERC20.at(await testIndex.buyTokenAddress());

        const indexTokenAddress = await testIndex.indexToken();
        indexToken = await IERC20.at(indexTokenAddress);

        await buyToken.approve(await testIndex.address, FUNDS_VALUE, { from: account });
    });

    it("should be able to add funds to the index", async () => {
        let initialBalance = parseFloat((await buyToken.balanceOf(account)).toString());
        console.log(await testIndex.addFunds(FUNDS_VALUE, { from: account, gas: 10000000 }));
        console.log("Account index token balance:", (await indexToken.balanceOf(account)).toString());
    });

    it("should return the price of the index", async () => {
        const price = await testIndex.getIndexPrice();
        console.log("Index price:", price.toString());
    });

});
