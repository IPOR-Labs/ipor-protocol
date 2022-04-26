const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");

const StrategyTestnetUsdt = artifacts.require("MockStrategyTestnetUsdt");
const StrategyTestnetUsdc = artifacts.require("MockStrategyTestnetUsdc");
const StrategyTestnetDai = artifacts.require("MockStrategyTestnetDai");

module.exports = async function (deployer, _network, addresses) {
    const stanleyUsdt = await func.get_value(keys.ItfStanleyProxyUsdt);
    const stanleyUsdc = await func.get_value(keys.ItfStanleyProxyUsdc);
    const stanleyDai = await func.get_value(keys.ItfStanleyProxyDai);

    const strategyTestnetUsdt = await func.get_value(keys.StrategyTestnetUsdtProxy);
    const strategyTestnetUsdc = await func.get_value(keys.StrategyTestnetUsdcProxy);
    const strategyTestnetDai = await func.get_value(keys.StrategyTestnetDaiProxy);

    const stanleyUsdtInstance = await StanleyUsdt.at(stanleyUsdt);
    const stanleyUsdcInstance = await StanleyUsdc.at(stanleyUsdc);
    const stanleyDaiInstance = await StanleyDai.at(stanleyDai);

    await stanleyUsdtInstance.setStrategyCompound(strategyTestnetUsdt);
    await stanleyUsdcInstance.setStrategyCompound(strategyTestnetUsdc);
    await stanleyDaiInstance.setStrategyCompound(strategyTestnetDai);

    const strategyTestnetUsdtInstance = await StrategyTestnetUsdt.at(strategyTestnetUsdt);
    const strategyTestnetUsdcInstance = await StrategyTestnetUsdc.at(strategyTestnetUsdc);
    const strategyTestnetDaiInstance = await StrategyTestnetDai.at(strategyTestnetDai);

    await strategyTestnetUsdtInstance.setStanley(stanleyUsdt);
    await strategyTestnetUsdcInstance.setStanley(stanleyUsdc);
    await strategyTestnetDaiInstance.setStanley(stanleyDai);
};
