require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const itfScript = require("../../libs/itf/deploy/itf_liquidator/dai/0001_initial_deploy.js");
const ItfLiquidator = artifacts.require("ItfLiquidator");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses, ItfLiquidator);
    }
    await func.updateLastCompletedMigration();
};
