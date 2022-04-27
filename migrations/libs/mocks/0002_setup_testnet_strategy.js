const keys = require("../json_keys.js");
const func = require("../json_func.js");

const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");

const StrategyTestnetUsdt = artifacts.require("MockStrategyTestnetUsdt");
const StrategyTestnetUsdc = artifacts.require("MockStrategyTestnetUsdc");
const StrategyTestnetDai = artifacts.require("MockStrategyTestnetDai");

module.exports = async function (deployer, _network, addresses) {
    const stanleyUsdt = await func.getValue(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.getValue(keys.StanleyProxyUsdc);
    const stanleyDai = await func.getValue(keys.StanleyProxyDai);

    const strategyTestnetUsdt = await func.getValue(keys.StrategyTestnetUsdtProxy);
    const strategyTestnetUsdc = await func.getValue(keys.StrategyTestnetUsdcProxy);
    const strategyTestnetDai = await func.getValue(keys.StrategyTestnetDaiProxy);

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
