const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");
const ItfMiltonDai = artifacts.require("ItfMiltonDai");

module.exports = async function (deployer, _network) {
    const josephUsdt = await func.get_value(keys.ItfJosephProxyUsdt);
    const josephUsdc = await func.get_value(keys.ItfJosephProxyUsdc);
    const josephDai = await func.get_value(keys.ItfJosephProxyDai);

    const stanleyUsdt = await func.get_value(keys.ItfStanleyProxyUsdt);
    const stanleyUsdc = await func.get_value(keys.ItfStanleyProxyUsdc);
    const stanleyDai = await func.get_value(keys.ItfStanleyProxyDai);

    const miltonUsdt = await func.get_value(keys.ItfMiltonProxyUsdt);
    const miltonUsdc = await func.get_value(keys.ItfMiltonProxyUsdc);
    const miltonDai = await func.get_value(keys.ItfMiltonProxyDai);

    const miltonUsdtInstance = await ItfMiltonUsdt.at(miltonUsdt);
    const miltonUsdcInstance = await ItfMiltonUsdc.at(miltonUsdc);
    const miltonDaiInstance = await ItfMiltonDai.at(miltonDai);

    await miltonUsdtInstance.setJoseph(josephUsdt);
    await miltonUsdcInstance.setJoseph(josephUsdc);
    await miltonDaiInstance.setJoseph(josephDai);

    await miltonUsdtInstance.setupMaxAllowanceForAsset(josephUsdt);
    await miltonUsdcInstance.setupMaxAllowanceForAsset(josephUsdc);
    await miltonDaiInstance.setupMaxAllowanceForAsset(josephDai);

    await miltonUsdtInstance.setupMaxAllowanceForAsset(stanleyUsdt);
    await miltonUsdcInstance.setupMaxAllowanceForAsset(stanleyUsdc);
    await miltonDaiInstance.setupMaxAllowanceForAsset(stanleyDai);
};
