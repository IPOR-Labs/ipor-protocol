const script = require("../../libs/contracts/upgrade/milton_storage/usdt/0001_prepare_upgrade.js");
const func = require("../../libs/json_func.js");
const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonStorageUsdt);
    await func.updateLastCompletedMigration();
};
