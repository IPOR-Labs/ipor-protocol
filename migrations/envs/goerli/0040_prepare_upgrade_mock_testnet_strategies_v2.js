require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/mocks/0003_prepare_upgrade_mock_testnet_strategies_v2.js");

const MockTestnetStrategyAaveUsdt = artifacts.require("MockTestnetStrategyAaveUsdt");
const MockTestnetStrategyAaveUsdc = artifacts.require("MockTestnetStrategyAaveUsdc");
const MockTestnetStrategyAaveDai = artifacts.require("MockTestnetStrategyAaveDai");

const MockTestnetStrategyCompoundUsdt = artifacts.require("MockTestnetStrategyCompoundUsdt");
const MockTestnetStrategyCompoundUsdc = artifacts.require("MockTestnetStrategyCompoundUsdc");
const MockTestnetStrategyCompoundDai = artifacts.require("MockTestnetStrategyCompoundDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, [
        MockTestnetStrategyAaveUsdt,
        MockTestnetStrategyAaveUsdc,
        MockTestnetStrategyAaveDai,
        MockTestnetStrategyCompoundUsdt,
        MockTestnetStrategyCompoundUsdc,
        MockTestnetStrategyCompoundDai,
    ]);
    await func.updateLastCompletedMigration();
};
