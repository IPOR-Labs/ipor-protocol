const keys = require("../json_keys.js");
const func = require("../json_func.js");

const MockTestnetStrategyAaveUsdt = artifacts.require("MockTestnetStrategyAaveUsdt");
const MockTestnetStrategyAaveUsdc = artifacts.require("MockTestnetStrategyAaveUsdc");
const MockTestnetStrategyAaveDai = artifacts.require("MockTestnetStrategyAaveDai");

const MockTestnetStrategyCompoundUsdt = artifacts.require("MockTestnetStrategyCompoundUsdt");
const MockTestnetStrategyCompoundUsdc = artifacts.require("MockTestnetStrategyCompoundUsdc");
const MockTestnetStrategyCompoundDai = artifacts.require("MockTestnetStrategyCompoundDai");

module.exports = async function (deployer, _network, addresses) {
    const strategyAaveUsdt = await func.getValue(keys.AaveStrategyProxyUsdt);
    const strategyAaveUsdc = await func.getValue(keys.AaveStrategyProxyUsdc);
    const strategyAaveDai = await func.getValue(keys.AaveStrategyProxyDai);

    const strategyCompoundUsdt = await func.getValue(keys.CompoundStrategyProxyUsdt);
    const strategyCompoundUsdc = await func.getValue(keys.CompoundStrategyProxyUsdc);
    const strategyCompoundDai = await func.getValue(keys.CompoundStrategyProxyDai);

    const stanleyUsdt = await func.getValue(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.getValue(keys.StanleyProxyUsdc);
    const stanleyDai = await func.getValue(keys.StanleyProxyDai);

    const strategyAaveUsdtInstance = await MockTestnetStrategyAaveUsdt.at(strategyAaveUsdt);
    const strategyAaveUsdcInstance = await MockTestnetStrategyAaveUsdc.at(strategyAaveUsdc);
    const strategyAaveDaiInstance = await MockTestnetStrategyAaveDai.at(strategyAaveDai);

    await strategyAaveUsdtInstance.setStanley(stanleyUsdt);
    await strategyAaveUsdcInstance.setStanley(stanleyUsdc);
    await strategyAaveDaiInstance.setStanley(stanleyDai);

    const strategyCompoundUsdtInstance = await MockTestnetStrategyCompoundUsdt.at(
        strategyCompoundUsdt
    );
    const strategyCompoundUsdcInstance = await MockTestnetStrategyCompoundUsdc.at(
        strategyCompoundUsdc
    );
    const strategyCompoundDaiInstance = await MockTestnetStrategyCompoundDai.at(
        strategyCompoundDai
    );

    await strategyCompoundUsdtInstance.setStanley(stanleyUsdt);
    await strategyCompoundUsdcInstance.setStanley(stanleyUsdc);
    await strategyCompoundDaiInstance.setStanley(stanleyDai);
};
