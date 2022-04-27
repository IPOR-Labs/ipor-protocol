require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley/dai/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/stanley/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfStanleyDai = artifacts.require("ItfStanleyDai");
        await itfScript(deployer, _network, addresses, ItfStanleyDai);
    } else {
        const StanleyDai = artifacts.require("StanleyDai");
        await script(deployer, _network, addresses, StanleyDai);
    }
	await func.updateLastCompletedMigration();
};
