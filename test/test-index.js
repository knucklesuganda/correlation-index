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
        await tokenIn.approve(testCorrelationIndex.address, FUNDS_VALUE + 1000, { from: ETH_WHALE });
    });

    it("returns index price bigger than 0", async () => {
        const price = (await testCorrelationIndex.getPrice());
        expect(price.toNumber()).to.be.above(0);
    });

    it("must add funds", async () => {
        await testCorrelationIndex.addFunds({ from: ETH_WHALE, value: FUNDS_VALUE });

        const indexPrice = (await testCorrelationIndex.getPrice()).toNumber();
        const totalValuePrice = (await testCorrelationIndex.getTVL()).toNumber();

        console.log(indexPrice, totalValuePrice);
        // expect(indexPrice).to.be.equal(totalValuePrice);
    });

});
