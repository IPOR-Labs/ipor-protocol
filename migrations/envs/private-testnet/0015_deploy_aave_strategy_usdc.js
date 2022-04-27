const script = require("../../libs/contracts/deploy/stanley_strategies/aave/usdc/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StrategyAaveUsdc);
	await func.updateLastCompletedMigration();
};
