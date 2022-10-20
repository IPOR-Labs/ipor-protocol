require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/joseph/weth/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/joseph/weth/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfJosephWeth = artifacts.require("ItfJosephWeth");
        await itfScript(
            deployer,
            _network,
            addresses,
            ItfJosephWeth,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_JOSEPH == "true" ? true : false
        );
    } else {
        const JosephWeth = artifacts.require("JosephWeth");
        await script(
            deployer,
            _network,
            addresses,
            JosephWeth,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_JOSEPH == "true" ? true : false
        );
    }
    await func.updateLastCompletedMigration();
};
