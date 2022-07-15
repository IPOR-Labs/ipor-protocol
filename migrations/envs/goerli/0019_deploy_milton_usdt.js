require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/deploy/milton/usdt/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const MiltonUsdt = artifacts.require("MiltonUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(
        deployer,
        _network,
        addresses,
        MiltonUsdt,
        process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON == "true" ? true : false
    );
    await func.updateLastCompletedMigration();
};
