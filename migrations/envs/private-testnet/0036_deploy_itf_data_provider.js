require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const itfScript = require("../../libs/itf/deploy/data_provider/0001_initial_deploy.js");
const ItfDataProvider = artifacts.require("ItfDataProvider");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses, ItfDataProvider);
    }
    await func.updateLastCompletedMigration();
};
