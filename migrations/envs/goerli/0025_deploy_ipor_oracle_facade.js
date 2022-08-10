const script = require("../../libs/contracts/deploy/ipor_oracle_facade/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IporOracleFacadeDataProvider);
    await func.updateLastCompletedMigration();
};
