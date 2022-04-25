const script = require("../../libs/contracts/deploy/ipor_oracle/0001_initial_deploy.js");

const IporOracle = artifacts.require("IporOracle");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IporOracle);
};
