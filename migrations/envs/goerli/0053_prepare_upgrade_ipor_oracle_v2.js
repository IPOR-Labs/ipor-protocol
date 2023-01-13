const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/ipor_oracle/0001_prepare_upgrade_v2.js");

const IporOracle = artifacts.require("IporOracle");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IporOracle);
    await func.updateLastCompletedMigration();
};
