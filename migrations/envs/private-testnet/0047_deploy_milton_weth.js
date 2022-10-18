require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/milton/weth/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/milton/weth/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonWeth = artifacts.require("ItfMiltonWeth");
        await itfScript(
            deployer,
            _network,
            addresses,
            ItfMiltonWeth,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON == "true" ? true : false
        );
    } else {
        const MiltonWeth = artifacts.require("MiltonWeth");
        await script(
            deployer,
            _network,
            addresses,
            MiltonWeth,
            process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON == "true" ? true : false
        );
    }
    await func.updateLastCompletedMigration();
};
