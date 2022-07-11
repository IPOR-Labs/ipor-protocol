const script = require("../../libs/contracts/deploy/stanley/usdc/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const StanleyUsdc = artifacts.require("StanleyUsdc");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StanleyUsdc);
    await func.updateLastCompletedMigration();
};
