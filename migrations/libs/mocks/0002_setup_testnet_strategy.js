const keys = require("../json_keys.js");
const func = require("../json_func.js");

const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");

module.exports = async function (deployer, _network, addresses) {
    const stanleyUsdt = await func.get_value(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.get_value(keys.StanleyProxyUsdc);
    const stanleyDai = await func.get_value(keys.StanleyProxyDai);

    const strategyTestnetUsdt = await func.get_value(keys.StrategyTestnetUsdtProxy);
    const strategyTestnetUsdc = await func.get_value(keys.StrategyTestnetUsdcProxy);
    const strategyTestnetDai = await func.get_value(keys.StrategyTestnetDaiProxy);

    const stanleyUsdtInstance = await StanleyUsdt.at(stanleyUsdt);
    const stanleyUsdcInstance = await StanleyUsdc.at(stanleyUsdc);
    const stanleyDaiInstance = await StanleyDai.at(stanleyDai);

    await stanleyUsdtInstance.setStrategyAave(strategyTestnetUsdt);
    await stanleyUsdcInstance.setStrategyAave(strategyTestnetUsdc);
    await stanleyDaiInstance.setStrategyAave(strategyTestnetDai);
};
