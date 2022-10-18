const script = require("../../libs/contracts/deploy/milton_storage/weth/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const MiltonStorageWeth = artifacts.require("MiltonStorageWeth");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonStorageWeth);
	await func.updateLastCompletedMigration();
};
