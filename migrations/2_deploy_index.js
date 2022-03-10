const Index = artifacts.require("./indices/CorrelationIndex.sol");

module.exports = function(deployer) {
    deployer.deploy(Index);
};
