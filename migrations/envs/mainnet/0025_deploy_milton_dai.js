require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/milton/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const MiltonDai = artifacts.require("MiltonDai");
    await script(deployer, _network, addresses, MiltonDai);
    await func.updateLastCompletedMigration();
};
