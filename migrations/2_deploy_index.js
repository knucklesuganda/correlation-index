var HelloWorld = artifacts.require("Index");

module.exports = function(deployer) {
    deployer.deploy(HelloWorld, "Index");
};
