const script = require("../../libs/contracts/deploy/stanley_strategies/compound/dai/0001_initial_deploy.js");

const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StrategyCompoundDai);
};
