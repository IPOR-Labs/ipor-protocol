require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/milton_storage/dai/0001_prepare_upgrade_v2.js");

module.exports = async function (deployer, _network, addresses) {
    const MiltonStorage = artifacts.require("MiltonStorageDai");
    await script(deployer, _network, addresses, MiltonStorage);
    await func.updateLastCompletedMigration();
};
