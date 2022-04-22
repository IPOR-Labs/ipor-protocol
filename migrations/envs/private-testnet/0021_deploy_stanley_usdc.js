require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/deploy/stanley/usdc/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/stanley/usdc/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
		const ItfStanleyUsdc = artifacts.require("ItfStanleyUsdc");
        await itfScript(deployer, _network, addresses, ItfStanleyUsdc);
    } else {
		const StanleyUsdc = artifacts.require("StanleyUsdc");
        await script(deployer, _network, addresses, StanleyUsdc);
    }
};
