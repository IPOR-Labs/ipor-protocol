require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const scriptInitial = require("../../libs/contracts/setup/milton/0001_initial_setup.js");

module.exports = async function (deployer, _network, addresses) {
    await scriptInitial(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};
