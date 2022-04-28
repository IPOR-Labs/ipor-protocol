const script = require("../../libs/contracts/deploy/joseph/usdt/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const JosephUsdt = artifacts.require("JosephUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, JosephUsdt);
    await func.updateLastCompletedMigration();
};
