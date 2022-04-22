const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const ItfStanleyUsdt = artifacts.require("ItfStanleyUsdt");
const ItfStanleyUsdc = artifacts.require("ItfStanleyUsdc");
const ItfStanleyDai = artifacts.require("ItfStanleyDai");

module.exports = async function (deployer, _network, addresses) {
    const stanleyUsdt = await func.get_value(keys.ItfStanleyProxyUsdt);
    const stanleyUsdc = await func.get_value(keys.ItfStanleyProxyUsdc);
    const stanleyDai = await func.get_value(keys.ItfStanleyProxyDai);

    const miltonUsdt = await func.get_value(keys.ItfMiltonProxyUsdt);
    const miltonUsdc = await func.get_value(keys.ItfMiltonProxyUsdc);
    const miltonDai = await func.get_value(keys.ItfMiltonProxyDai);

    const stanleyUsdtInstance = await ItfStanleyUsdt.at(stanleyUsdt);
    const stanleyUsdcInstance = await ItfStanleyUsdc.at(stanleyUsdc);
    const stanleyDaiInstance = await ItfStanleyDai.at(stanleyDai);

    await stanleyUsdtInstance.setMilton(miltonUsdt);
    await stanleyUsdcInstance.setMilton(miltonUsdc);
    await stanleyDaiInstance.setMilton(miltonDai);
};
