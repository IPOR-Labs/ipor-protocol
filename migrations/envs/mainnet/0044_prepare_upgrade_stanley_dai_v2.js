require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley/dai/0001_prepare_upgrade_v2.js");

module.exports = async function (deployer, _network, addresses) {
    const StanleyDai = artifacts.require("StanleyDai");
    await script(deployer, _network, addresses, StanleyDai);
    await func.updateLastCompletedMigration();
};
