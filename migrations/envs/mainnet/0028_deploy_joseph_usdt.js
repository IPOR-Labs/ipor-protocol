require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/joseph/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const JosephUsdt = artifacts.require("JosephUsdt");
    await script(
        deployer,
        _network,
        addresses,
        JosephUsdt,
        process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_JOSEPH
    );
    await func.updateLastCompletedMigration();
};
