const script = require("../../libs/contracts/deploy/stanley_strategies/aave/usdt/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StrategyAaveUsdt);
	await func.updateLastCompletedMigration();
};
