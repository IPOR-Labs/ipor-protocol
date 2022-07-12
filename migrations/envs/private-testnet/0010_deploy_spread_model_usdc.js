const script = require("../../libs/contracts/deploy/spread_model/usdc/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/spread_model/usdc/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonSpreadModelUsdc = artifacts.require("ItfMiltonSpreadModelUsdc");
        await itfScript(deployer, _network, addresses, ItfMiltonSpreadModelUsdc);
    } else {
        const MiltonSpreadModelUsdc = artifacts.require("MiltonSpreadModelUsdc");
        await script(deployer, _network, addresses, MiltonSpreadModelUsdc);
    }
    await func.updateLastCompletedMigration();
};
