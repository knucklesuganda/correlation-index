const BaseIndex = artifacts.require("./indices/BaseIndex.sol");
const Observer = artifacts.require('./management/Observer.sol');


module.exports = async function(deployer) {
    
    await deployer.deploy(
        BaseIndex,
        '0xE592427A0AEce92De3Edee1F18E0157C05861564', 
        '0x1F98431c8aD98523631AE4a59f267346ea31F984', 
        '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', 
        '0x6B175474E89094C44Da98b954EedeAC495271d0F', 
        'Void Index Token', 
        'VID',
    );
    await deployer.deploy(Observer);

    const index = await BaseIndex.deployed();
    const observer = await Observer.deployed();

    await observer.addProduct(index.address, "index");

};
