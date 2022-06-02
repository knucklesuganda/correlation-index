require("chai").use(require("chai-bignumber")(web3.BigNumber)).should();
const BN = require("bn.js");
const { assert } = require("chai");
const BaseIndex = artifacts.require("BaseIndex.sol");
const IERC20 = artifacts.require("IERC20");


contract('BaseIndex', (accounts) => {

    let buyToken;
    let indexToken;
    let index;
    const account = process.env.ETH_WHALE;
    const indexOwner = accounts[0];
    let FUNDS_VALUE;

    beforeEach(async () => {
        index = await BaseIndex.new(
            '0xE592427A0AEce92De3Edee1F18E0157C05861564',
            '0x1F98431c8aD98523631AE4a59f267346ea31F984',
            '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', 
            '0x6B175474E89094C44Da98b954EedeAC495271d0F',
            'Void Index Token',
            'VID',
            { from: indexOwner },
        );
        buyToken = await IERC20.at(await index.buyTokenAddress());
        indexToken = await IERC20.at(await index.indexToken());

        FUNDS_VALUE = new BN("1000000000000000000000", 10);     // 1000$
        await buyToken.approve(await index.address, FUNDS_VALUE, { from: account });
    });

    it("should return index owner", async (accounts) => {
        const owner = await index.owner({ from: accounts[0], gasLimit: 100000 });
        assert.equal(owner, indexOwner);
    });

    const buyTokens = async () => {
        await buyToken.approve(index.address, FUNDS_VALUE, { from: account });

        const price = await index.getPrice();
        const tokensBought = FUNDS_VALUE.div(price);

        await index.buy(tokensBought, { from: account });
        const feeData = await index.getFee();

        const fee = (100 / feeData[1].toNumber()) * feeData[0].toNumber();
        return [tokensBought, fee];
    };
    
    it("must add funds according to the price", async () => {
        const [tokensBought, fee] = await buyTokens();

        assert.equal(
            await index.getUserDebt(account, true),
            tokensBought.sub(tokensBought.div(100).mul(fee))
        );

    });

    it("must settle the tokens", async () => {
        await buyTokens();

        const components = await index.getComponents();
        await index.beginSettlement({ from: indexOwner });

        for (const component of components) {
            await index.manageTokens({ from: indexOwner });
        }
    
        await index.endSettlement({ from: indexOwner });
    });

    it("should return the price of the index", async () => {
        const price = await index.getPrice();
        console.log("Index price:", price.toString());
    });

    // it("should increase the balance of the index owner by fee", async () => {
    //     const balanceBefore = await buyToken.balanceOf(indexOwner);
    //     await index.buy(FUNDS_VALUE, { from: account });
    //     const balanceAfter = await buyToken.balanceOf(indexOwner);
    // 
    //     console.log("Balance before: ", balanceBefore.toString(), " Balance after:", balanceAfter.toString());
    //     const fee = FUNDS_VALUE.div(100).mul(await index.productFee());
    //     assert.equal(balanceAfter.sub(balanceBefore).toString(), fee.toString());
    // });
    // it("should be able to add funds to the index", async () => {
    //     console.log(await index.buy(FUNDS_VALUE, { from: account }));
    //     console.log("Account index token balance:", (await indexToken.balanceOf(account)).toString());
    // });
    // 
    // it("should withdraw funds from the index", async () => {
    //     console.log(await index.buy(FUNDS_VALUE, { from: account }));
    //     const tokenFunds = await indexToken.balanceOf(account);
    // 
    //     await indexToken.approve(await index.address, tokenFunds, { from: account });
    // 
    //     /////////////////////////////////////////////////////////////////////////
    //     console.log(
    //         'ETH:', (await (
    //             await IERC20.at('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
    //         ).balanceOf(await index.address)).toString(),
    // 
    //         '\n',
    // 
    //         'BTC:', (await (
    //             await IERC20.at('0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599')
    //         ).balanceOf(await index.address)).toString()
    //     );
    //     /////////////////////////////////////////////////////////////////////////
    // 
    //     await index.sell(tokenFunds, { from: account });
    //     console.log("Account DAI balance:", (await buyToken.balanceOf(account)).toString());
    // });

});
