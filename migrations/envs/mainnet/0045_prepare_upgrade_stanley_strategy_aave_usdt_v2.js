require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley_strategies/aave/usdt/0001_prepare_upgrade_v2.js");

module.exports = async function (deployer, _network, addresses) {
    const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");
    await script(deployer, _network, addresses, StrategyAaveUsdt);
    await func.updateLastCompletedMigration();
};
