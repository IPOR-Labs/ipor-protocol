require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/milton/usdt/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/milton/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
        await itfScript(
            deployer,
            _network,
            addresses,
            ItfMiltonUsdt,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON
        );
    } else {
        const MiltonUsdt = artifacts.require("MiltonUsdt");
        await script(
            deployer,
            _network,
            addresses,
            MiltonUsdt,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON
        );
    }
    await func.updateLastCompletedMigration();
};
