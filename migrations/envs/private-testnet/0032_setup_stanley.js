require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/setup/stanley/0001_initial_setup.js");
const itfScript = require("../../libs/itf/setup/stanley/0001_initial_setup.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses);
    } else {
        await script(deployer, _network, addresses);
    }
	await func.updateLastCompletedMigration();
};
