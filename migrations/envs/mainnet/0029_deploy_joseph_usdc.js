require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/joseph/usdc/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const JosephUsdc = artifacts.require("JosephUsdc");
    await script(
        deployer,
        _network,
        addresses,
        JosephUsdc,
        process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_JOSEPH == "true" ? true : false
    );
    await func.updateLastCompletedMigration();
};
