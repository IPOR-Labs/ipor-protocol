const script = require("../../libs/contracts/deploy/stanley_strategies/aave/dai/0001_initial_deploy.js");

const StrategyAaveDai = artifacts.require("StrategyAaveDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StrategyAaveDai);
};
