const script = require("../../libs/contracts/deploy/ipor_oracle_facade/0001_initial_deploy.js");

const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IporOracleFacadeDataProvider);
};
