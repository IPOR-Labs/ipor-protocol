const script = require("../../libs/contracts/deploy/spread_model/0002_deploy_v2.js");
const func = require("../../libs/json_func.js");
const MiltonSpreadModelV2 = artifacts.require("MiltonSpreadModelV2");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonSpreadModelV2);
	await func.updateLastCompletedMigration();
};
