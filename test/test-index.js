require("chai").use(require("chai-bignumber")(web3.BigNumber)).should();
const { expect } = require("chai");
const CorrelationIndex = artifacts.require("CorrelationIndex");
const IERC20 = artifacts.require("IERC20");


contract('CorrelationIndex', (accounts) => {

    const ETH_WHALE = process.env.ETH_WHALE;
    const FUNDS_VALUE = 1000000;
    let tokenIn;
    let testCorrelationIndex;

    beforeEach(async () => {
        testCorrelationIndex = await CorrelationIndex.new();
        tokenIn = await IERC20.at(process.env.WETH);
        await tokenIn.approve(testCorrelationIndex.address, FUNDS_VALUE, { from: ETH_WHALE });
    });

    it("returns index price bigger than 0", async () => {
        const price = (await testCorrelationIndex.getPrice());
        expect(price.toNumber()).to.be.above(0);
    });

    it("must add funds to the tokens and leave zero in itself", async () => {
        await testCorrelationIndex.addFunds({ from: ETH_WHALE, value: FUNDS_VALUE });
        const indexBalance = await web3.eth.getBalance(testCorrelationIndex.address);
        expect(indexBalance).equal(0);
    });

    it("must get funds from the user account", async () => {
        const userInitialBalance = await web3.eth.getBalance(ETH_WHALE);
        await testCorrelationIndex.addFunds({ from: ETH_WHALE, value: FUNDS_VALUE });
        const userFundsBalance = await web3.eth.getBalance(ETH_WHALE);
        userFundsBalance.should.be.bignumber.equal(userInitialBalance - FUNDS_VALUE);
    });

});
