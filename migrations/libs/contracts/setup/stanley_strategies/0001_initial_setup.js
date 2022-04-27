const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");
const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");
const StrategyAaveDai = artifacts.require("StrategyAaveDai");
const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");
const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");
const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");

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

    const strategyAaveUsdtInstance = await StrategyAaveUsdt.at(strategyAaveUsdt);
    const strategyAaveUsdcInstance = await StrategyAaveUsdc.at(strategyAaveUsdc);
    const strategyAaveDaiInstance = await StrategyAaveDai.at(strategyAaveDai);

    await strategyAaveUsdtInstance.setStanley(stanleyUsdt);
    await strategyAaveUsdcInstance.setStanley(stanleyUsdc);
    await strategyAaveDaiInstance.setStanley(stanleyDai);

    const strategyCompoundUsdtInstance = await StrategyCompoundUsdt.at(strategyCompoundUsdt);
    const strategyCompoundUsdcInstance = await StrategyCompoundUsdc.at(strategyCompoundUsdc);
    const strategyCompoundDaiInstance = await StrategyCompoundDai.at(strategyCompoundDai);

    await strategyCompoundUsdtInstance.setStanley(stanleyUsdt);
    await strategyCompoundUsdcInstance.setStanley(stanleyUsdc);
    await strategyCompoundDaiInstance.setStanley(stanleyDai);
};
