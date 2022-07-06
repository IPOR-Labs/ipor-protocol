const script = require("../../libs/contracts/deploy/spread_model/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonSpreadModel);
	await func.updateLastCompletedMigration();
};
