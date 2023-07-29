require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/stanley_strategies/dsr/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const Strategy = artifacts.require("StrategyDsrDai");
    await script(deployer, _network, addresses, Strategy);
    await func.updateLastCompletedMigration();
};
