const script = require("../../libs/contracts/deploy/spread_model/usdt/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    const MiltonSpreadModelUsdt = artifacts.require("MiltonSpreadModelUsdt");
    await script(deployer, _network, addresses, MiltonSpreadModelUsdt);
    await func.updateLastCompletedMigration();
};
