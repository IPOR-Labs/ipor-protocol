const IporOracle = artifacts.require("IporOracle");

module.exports = function (deployer) {
    deployer.deploy(IporOracle);
};