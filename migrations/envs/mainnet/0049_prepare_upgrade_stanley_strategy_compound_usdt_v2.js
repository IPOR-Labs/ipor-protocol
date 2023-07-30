require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley_strategies/compound/usdt/0001_prepare_upgrade_v2.js");

module.exports = async function (deployer, _network, addresses) {
    const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");
    await script(deployer, _network, addresses, StrategyCompoundUsdt);
    await func.updateLastCompletedMigration();
};