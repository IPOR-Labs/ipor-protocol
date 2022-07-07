const script = require("../../libs/contracts/deploy/spread_model/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/spread_model/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonSpreadModel = artifacts.require("ItfMiltonSpreadModel");
        await itfScript(deployer, _network, addresses, ItfMiltonSpreadModel);
    } else {
        const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
        await script(deployer, _network, addresses, MiltonSpreadModel);
    }
    await func.updateLastCompletedMigration();
};
