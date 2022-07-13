require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley_strategies/aave/usdc/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");
    await script(deployer, _network, addresses, StrategyAaveUsdc);
    await func.updateLastCompletedMigration();
};
