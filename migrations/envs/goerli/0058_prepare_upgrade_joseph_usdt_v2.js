require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/joseph/usdt/0001_prepare_upgrade_v2.js");

module.exports = async function (deployer, _network, addresses) {
    const Joseph = artifacts.require("JosephUsdt");
    await script(deployer, _network, addresses, Joseph);
    await func.updateLastCompletedMigration();
};
