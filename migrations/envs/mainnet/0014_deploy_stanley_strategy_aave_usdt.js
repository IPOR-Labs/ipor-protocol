require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley_strategies/aave/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");
    await script(deployer, _network, addresses, StrategyAaveUsdt);
    await func.updateLastCompletedMigration();
};
