const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");

module.exports = async function (deployer, _network, addresses) {
    const stanleyUsdt = await func.getValue(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.getValue(keys.StanleyProxyUsdc);
    const stanleyDai = await func.getValue(keys.StanleyProxyDai);

    const miltonUsdt = await func.getValue(keys.MiltonProxyUsdt);
    const miltonUsdc = await func.getValue(keys.MiltonProxyUsdc);
    const miltonDai = await func.getValue(keys.MiltonProxyDai);

    const stanleyUsdtInstance = await StanleyUsdt.at(stanleyUsdt);
    const stanleyUsdcInstance = await StanleyUsdc.at(stanleyUsdc);
    const stanleyDaiInstance = await StanleyDai.at(stanleyDai);

    await stanleyUsdtInstance.setMilton(miltonUsdt);
    await stanleyUsdcInstance.setMilton(miltonUsdc);
    await stanleyDaiInstance.setMilton(miltonDai);
};
