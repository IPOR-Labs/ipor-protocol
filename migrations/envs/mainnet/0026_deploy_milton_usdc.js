require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/milton/usdc/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const MiltonUsdc = artifacts.require("MiltonUsdc");
    await script(
        deployer,
        _network,
        addresses,
        MiltonUsdc,
        process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON
    );
    await func.updateLastCompletedMigration();
};
