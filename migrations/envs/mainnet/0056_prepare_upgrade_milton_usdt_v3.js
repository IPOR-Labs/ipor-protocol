require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/milton/usdt/0002_prepare_upgrade_v3_only_mainnet.js");

module.exports = async function (deployer, _network, addresses) {
    const Milton = artifacts.require("MiltonUsdt");
    await script(deployer, _network, addresses, Milton);
    await func.updateLastCompletedMigration();
};
