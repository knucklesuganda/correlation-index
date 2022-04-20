const BaseIndex = artifacts.require("./indices/BaseIndex.sol");
const Observer = artifacts.require('./management/Observer.sol');


module.exports = async function(deployer) {
    
    await deployer.deploy(BaseIndex);
    await deployer.deploy(Observer);

    const index = await BaseIndex.deployed();
    const observer = await Observer.deployed();

    await observer.addProduct(index.address, "index");
    console.log("Observer:", observer.address);

};
