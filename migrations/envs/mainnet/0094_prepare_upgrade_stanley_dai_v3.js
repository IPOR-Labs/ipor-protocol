require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley/dai/0001_prepare_upgrade_v3.js");

module.exports = async function (deployer, _network, addresses) {
    const StanleyDsrDai = artifacts.require("StanleyDsrDai");
    await script(deployer, _network, addresses, StanleyDsrDai);
    await func.updateLastCompletedMigration();
};
