const script = require("../../libs/contracts/upgrade/milton_storage/usdc/0001_prepare_upgrade.js");
const func = require("../../libs/json_func.js");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonStorageUsdc);
	await func.updateLastCompletedMigration();
};
