const script = require("../../libs/contracts/deploy/spread_model/usdc/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    const MiltonSpreadModelUsdc = artifacts.require("MiltonSpreadModelUsdc");
    await script(deployer, _network, addresses, MiltonSpreadModelUsdc);
    await func.updateLastCompletedMigration();
};
