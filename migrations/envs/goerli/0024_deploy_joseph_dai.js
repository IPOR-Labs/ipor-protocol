require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/deploy/joseph/dai/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const JosephDai = artifacts.require("JosephDai");

module.exports = async function (deployer, _network, addresses) {
    await script(
        deployer,
        _network,
        addresses,
        JosephDai,
        process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_JOSEPH == "true" ? true : false
    );
    await func.updateLastCompletedMigration();
};
