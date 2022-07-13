require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/setup/ipor_oracle/0001_initial_setup.js");

module.exports = async function (deployer, _network, addresses) {
	//TODO: consider if after deployment updater should be setup
    await script(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};
