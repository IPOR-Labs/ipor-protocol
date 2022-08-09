require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley_strategies/compound/usdc/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");
    await script(deployer, _network, addresses, StrategyCompoundUsdc);
    await func.updateLastCompletedMigration();
};
