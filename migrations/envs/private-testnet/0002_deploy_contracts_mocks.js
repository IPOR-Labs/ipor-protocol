const { exit } = require("process");
const func = require("../../libs/json_func.js");
const script = require("../../libs/mocks/0001_deploy_mocks_and_faucet.js");

const MockTestnetTokenUsdt = artifacts.require("MockTestnetTokenUsdt");
const MockTestnetTokenUsdc = artifacts.require("MockTestnetTokenUsdc");
const MockTestnetTokenDai = artifacts.require("MockTestnetTokenDai");

const MockTestnetShareTokenAaveUsdt = artifacts.require("MockTestnetShareTokenAaveUsdt");
const MockTestnetShareTokenAaveUsdc = artifacts.require("MockTestnetShareTokenAaveUsdc");
const MockTestnetShareTokenAaveDai = artifacts.require("MockTestnetShareTokenAaveDai");

const MockTestnetShareTokenCompoundUsdt = artifacts.require("MockTestnetShareTokenCompoundUsdt");
const MockTestnetShareTokenCompoundUsdc = artifacts.require("MockTestnetShareTokenCompoundUsdc");
const MockTestnetShareTokenCompoundDai = artifacts.require("MockTestnetShareTokenCompoundDai");

const MockTestnetStrategyAaveUsdt = artifacts.require("MockTestnetStrategyAaveUsdt");
const MockTestnetStrategyAaveUsdc = artifacts.require("MockTestnetStrategyAaveUsdc");
const MockTestnetStrategyAaveDai = artifacts.require("MockTestnetStrategyAaveDai");

const MockTestnetStrategyCompoundUsdt = artifacts.require("MockTestnetStrategyCompoundUsdt");
const MockTestnetStrategyCompoundUsdc = artifacts.require("MockTestnetStrategyCompoundUsdc");
const MockTestnetStrategyCompoundDai = artifacts.require("MockTestnetStrategyCompoundDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, [
        MockTestnetTokenUsdt,
        MockTestnetTokenUsdc,
        MockTestnetTokenDai,
        MockTestnetShareTokenAaveUsdt,
        MockTestnetShareTokenAaveUsdc,
        MockTestnetShareTokenAaveDai,
        MockTestnetShareTokenCompoundUsdt,
        MockTestnetShareTokenCompoundUsdc,
        MockTestnetShareTokenCompoundDai,
        MockTestnetStrategyAaveUsdt,
        MockTestnetStrategyAaveUsdc,
        MockTestnetStrategyAaveDai,
        MockTestnetStrategyCompoundUsdt,
        MockTestnetStrategyCompoundUsdc,
        MockTestnetStrategyCompoundDai,
    ]);
    await func.updateLastCompletedMigration();
};
