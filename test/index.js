const contract = artifacts.require("Index");
const contract_address = '0x645A95396bC3c2f1F64121EAaDAF47F83e7b7fc4';

const MetaCoin = artifacts.require("MetaCoin");

contract("2nd MetaCoin test", async accounts => {
    const instance = await Index.deployed();

    // balances;
    // totalSupply;
    // name;
    // decimals;
    // symbol;
    // owner;

    it("initial balances must be empty", async () => {
        const balance = await instance.getBalance.call(accounts[0]);
        assert.equal(balance.valueOf(), 10000);
    });

    it("should call a function that depends on a linked library", async () => {
        const meta = await MetaCoin.deployed();
        const outCoinBalance = await meta.getBalance.call(accounts[0]);
        const metaCoinBalance = outCoinBalance.toNumber();
        const outCoinBalanceEth = await meta.getBalanceInEth.call(accounts[0]);
        const metaCoinEthBalance = outCoinBalanceEth.toNumber();
        assert.equal(metaCoinEthBalance, 2 * metaCoinBalance);
    });

});