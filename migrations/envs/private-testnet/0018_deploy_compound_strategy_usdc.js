const script = require("../../libs/contracts/deploy/stanley_strategies/compound/usdc/0001_initial_deploy.js");

const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StrategyCompoundUsdc);
};
