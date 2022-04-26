require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley/usdt/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/stanley/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfStanleyUsdt = artifacts.require("ItfStanleyUsdt");
        await itfScript(deployer, _network, addresses, ItfStanleyUsdt);
    } else {
        const StanleyUsdt = artifacts.require("StanleyUsdt");
        await script(deployer, _network, addresses, StanleyUsdt);
    }
	await func.updateLastCompletedMigration();
};
