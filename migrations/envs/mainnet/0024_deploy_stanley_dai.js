require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const StanleyDai = artifacts.require("StanleyDai");
    await script(deployer, _network, addresses, StanleyDai);
    await func.updateLastCompletedMigration();
};
