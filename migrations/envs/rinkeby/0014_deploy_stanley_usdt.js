const script = require("../../libs/contracts/deploy/stanley/usdt/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const StanleyUsdt = artifacts.require("StanleyUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StanleyUsdt);
    await func.updateLastCompletedMigration();
};
