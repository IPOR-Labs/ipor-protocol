const script = require("../../libs/contracts/deploy/joseph/usdc/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const JosephUsdc = artifacts.require("JosephUsdc");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, JosephUsdc);
    await func.updateLastCompletedMigration();
};
