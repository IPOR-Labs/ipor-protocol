const script = require("../../libs/contracts/deploy/multicall/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const Multicall2 = artifacts.require("Multicall2");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, Multicall2);
	await func.updateLastCompletedMigration();
};
