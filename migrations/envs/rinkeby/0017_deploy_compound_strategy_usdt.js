const script = require("../../libs/contracts/deploy/stanley_strategies/compound/usdt/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StrategyCompoundUsdt);
    await func.updateLastCompletedMigration();
};
