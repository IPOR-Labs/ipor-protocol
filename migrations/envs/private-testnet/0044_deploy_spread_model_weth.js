const script = require("../../libs/contracts/deploy/spread_model/weth/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/spread_model/weth/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonSpreadModelWeth = artifacts.require("ItfMiltonSpreadModelWeth");
        await itfScript(deployer, _network, addresses, ItfMiltonSpreadModelWeth);
    } else {
        const MiltonSpreadModelWeth = artifacts.require("MiltonSpreadModelWeth");
        await script(deployer, _network, addresses, MiltonSpreadModelWeth);
    }
    await func.updateLastCompletedMigration();
};
