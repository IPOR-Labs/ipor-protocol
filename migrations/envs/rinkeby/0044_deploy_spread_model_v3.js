const script = require("../../libs/contracts/deploy/spread_model/0003_deploy_v3.js");
const func = require("../../libs/json_func.js");
const MiltonSpreadModelV3 = artifacts.require("MiltonSpreadModelV3");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonSpreadModelV3);
    await func.updateLastCompletedMigration();
};
