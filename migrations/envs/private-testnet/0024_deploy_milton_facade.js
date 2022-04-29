require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/milton_facade/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/milton_facade/0001_initial_deploy.js");
const MiltonFacadeDataProvider = artifacts.require("MiltonFacadeDataProvider");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses, MiltonFacadeDataProvider);
    } else {
        await script(deployer, _network, addresses, MiltonFacadeDataProvider);
    }
	await func.updateLastCompletedMigration();
};
