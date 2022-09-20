require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley_strategies/aave/dai/0001_prepare_upgrade_v2.js");

module.exports = async function (deployer, _network, addresses) {
    const StrategyAaveDai = artifacts.require("StrategyAaveDai");
    await script(deployer, _network, addresses, StrategyAaveDai);
    await func.updateLastCompletedMigration();
};
