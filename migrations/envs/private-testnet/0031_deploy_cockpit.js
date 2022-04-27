require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/cockpit/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/cockpit/0001_initial_deploy.js");
const CockpitDataProvider = artifacts.require("CockpitDataProvider");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses, CockpitDataProvider);
    } else {
        await script(deployer, _network, addresses, CockpitDataProvider);
    }
	await func.updateLastCompletedMigration();
};
