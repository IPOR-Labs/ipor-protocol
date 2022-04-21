const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");

module.exports = async function (deployer, _network) {
    const stanleyUsdt = await func.get_value(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.get_value(keys.StanleyProxyUsdc);
    const stanleyDai = await func.get_value(keys.StanleyProxyDai);

    const miltonUsdt = await func.get_value(keys.MiltonProxyUsdt);
    const miltonUsdc = await func.get_value(keys.MiltonProxyUsdc);
    const miltonDai = await func.get_value(keys.MiltonProxyDai);

    const stanleyUsdtInstance = await StanleyUsdt.at(stanleyUsdt);
    const stanleyUsdcInstance = await StanleyUsdc.at(stanleyUsdc);
    const stanleyDaiInstance = await StanleyDai.at(stanleyDai);

    await stanleyUsdtInstance.setMilton(miltonUsdt);
    await stanleyUsdcInstance.setMilton(miltonUsdc);
    await stanleyDaiInstance.setMilton(miltonDai);
};
