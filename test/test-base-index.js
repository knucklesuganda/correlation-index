require("chai").use(require("chai-bignumber")(web3.BigNumber)).should();
const BN = require("bn.js");
const CorrelationIndex = artifacts.require("CorrelationIndex");
const IERC20 = artifacts.require("IERC20");


contract('CorrelationIndex', (accounts) => {

    let buyToken;
    let indexToken;
    let testCorrelationIndex;
    const account = process.env.ETH_WHALE;
    const FUNDS_VALUE = 10000;

    beforeEach(async () => {
        testCorrelationIndex = await CorrelationIndex.new();
        buyToken = await IERC20.at(await testCorrelationIndex.buyTokenAddress());

        const indexTokenAddress = await testCorrelationIndex.indexToken();
        indexToken = await IERC20.at(indexTokenAddress);

        await buyToken.approve(await testCorrelationIndex.address, FUNDS_VALUE, { from: account });
    });

    it("should be able to add funds to the index", async () => {
        let initialBalance = parseFloat((await buyToken.balanceOf(account)).toString());
        console.log(await testCorrelationIndex.addFunds(FUNDS_VALUE, { from: account }));
        const finalBalance = parseFloat((await buyToken.balanceOf(account)).toString());

        console.log(await indexToken.balanceOf(account));
    });

});
