const CorrelationIndex = artifacts.require("CorrelationIndex");
const IERC20 = artifacts.require("IERC20");
const contract_address = '0x645A95396bC3c2f1F64121EAaDAF47F83e7b7fc4';

contract('CorrelationIndex', (accounts) => {

    const ETH_WHALE = process.env.ETH_WHALE;
    const FUNDS_VALUE = 100000000000;
    let tokenIn;
    let testCorrelationIndex;

    beforeEach(async () => {
        testCorrelationIndex = await CorrelationIndex.new();
        tokenIn = await IERC20.at(process.env.WETH);
        await tokenIn.approve(testCorrelationIndex.address, FUNDS_VALUE, { from: ETH_WHALE });
    });

    it("returns index price", async () => {
        const price = await testCorrelationIndex.getPrice();
        console.log(price);
    });

    it("must swap tokens", async () => {
        await testCorrelationIndex.addFunds({ from: ETH_WHALE, value: FUNDS_VALUE });
        console.log(`Balance: ${await testCorrelationIndex.balance()}`);
    });

});
