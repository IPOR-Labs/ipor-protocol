const script = require("../../libs/contracts/upgrade/milton_storage/dai/0001_prepare_upgrade.js");
const func = require("../../libs/json_func.js");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonStorageDai);
    await func.updateLastCompletedMigration();
};
