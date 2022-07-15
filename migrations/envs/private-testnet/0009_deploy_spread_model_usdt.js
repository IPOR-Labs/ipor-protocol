const script = require("../../libs/contracts/deploy/spread_model/usdt/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/spread_model/usdt/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonSpreadModelUsdt = artifacts.require("ItfMiltonSpreadModelUsdt");
        await itfScript(deployer, _network, addresses, ItfMiltonSpreadModelUsdt);
    } else {
        const MiltonSpreadModelUsdt = artifacts.require("MiltonSpreadModelUsdt");
        await script(deployer, _network, addresses, MiltonSpreadModelUsdt);
    }
    await func.updateLastCompletedMigration();
};
