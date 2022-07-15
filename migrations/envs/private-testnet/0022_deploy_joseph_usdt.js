require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/joseph/usdt/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/joseph/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfJosephUsdt = artifacts.require("ItfJosephUsdt");
        await itfScript(
            deployer,
            _network,
            addresses,
            ItfJosephUsdt,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_JOSEPH == "true" ? true : false
        );
    } else {
        const JosephUsdt = artifacts.require("JosephUsdt");
        await script(
            deployer,
            _network,
            addresses,
            JosephUsdt,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_JOSEPH == "true" ? true : false
        );
    }
    await func.updateLastCompletedMigration();
};
