const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");
const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");
const StrategyAaveDai = artifacts.require("StrategyAaveDai");
const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");
const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");
const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");

module.exports = async function (deployer, _network, addresses) {
    const strategyAaveUsdt = await func.get_value(keys.AaveStrategyProxyUsdt);
    const strategyAaveUsdc = await func.get_value(keys.AaveStrategyProxyUsdc);
    const strategyAaveDai = await func.get_value(keys.AaveStrategyProxyDai);

    const strategyCompoundUsdt = await func.get_value(keys.CompoundStrategyProxyUsdt);
    const strategyCompoundUsdc = await func.get_value(keys.CompoundStrategyProxyUsdc);
    const strategyCompoundDai = await func.get_value(keys.CompoundStrategyProxyDai);

    const stanleyUsdt = await func.get_value(keys.ItfStanleyProxyUsdt);
    const stanleyUsdc = await func.get_value(keys.ItfStanleyProxyUsdc);
    const stanleyDai = await func.get_value(keys.ItfStanleyProxyDai);

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
