require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley_strategies/aave/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const StrategyAaveDai = artifacts.require("StrategyAaveDai");
    await script(deployer, _network, addresses, StrategyAaveDai);
    await func.updateLastCompletedMigration();
};
