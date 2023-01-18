require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/milton/usdc/0002_prepare_upgrade_v3.js");

module.exports = async function (deployer, _network, addresses) {
    const Milton = artifacts.require("MiltonUsdc");
    await script(deployer, _network, addresses, Milton);
    await func.updateLastCompletedMigration();
};
