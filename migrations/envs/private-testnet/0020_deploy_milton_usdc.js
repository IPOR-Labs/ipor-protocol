require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/milton/usdc/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/milton/usdc/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");
        await itfScript(
            deployer,
            _network,
            addresses,
            ItfMiltonUsdc,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON == "true" ? true : false
        );
    } else {
        const MiltonUsdc = artifacts.require("MiltonUsdc");
        await script(
            deployer,
            _network,
            addresses,
            MiltonUsdc,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON == "true" ? true : false
        );
    }
    await func.updateLastCompletedMigration();
};
