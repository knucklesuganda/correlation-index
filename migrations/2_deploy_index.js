const Index = artifacts.require("./indices/Index.sol");
const Observer = artifacts.require('./management/Observer.sol');


module.exports = async function(deployer, network, accounts) {
    console.log(accounts);

    await deployer.deploy(Index);
    await deployer.deploy(Observer);

    const index = await Index.deployed();
    const observer = await Observer.deployed();

    await observer.addProduct(index.address, "index");
};
