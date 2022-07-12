require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/milton/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const MiltonUsdt = artifacts.require("MiltonUsdt");
    await script(deployer, _network, addresses, MiltonUsdt);
    await func.updateLastCompletedMigration();
};
