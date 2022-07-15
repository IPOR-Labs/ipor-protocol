require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley_strategies/compound/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");
    await script(deployer, _network, addresses, StrategyCompoundDai);
    await func.updateLastCompletedMigration();
};
