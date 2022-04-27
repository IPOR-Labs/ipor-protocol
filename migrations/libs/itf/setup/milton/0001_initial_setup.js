const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");
const ItfMiltonDai = artifacts.require("ItfMiltonDai");

module.exports = async function (deployer, _network, addresses) {
    const josephUsdt = await func.getValue(keys.ItfJosephProxyUsdt);
    const josephUsdc = await func.getValue(keys.ItfJosephProxyUsdc);
    const josephDai = await func.getValue(keys.ItfJosephProxyDai);

    const stanleyUsdt = await func.getValue(keys.ItfStanleyProxyUsdt);
    const stanleyUsdc = await func.getValue(keys.ItfStanleyProxyUsdc);
    const stanleyDai = await func.getValue(keys.ItfStanleyProxyDai);

    const miltonUsdt = await func.getValue(keys.ItfMiltonProxyUsdt);
    const miltonUsdc = await func.getValue(keys.ItfMiltonProxyUsdc);
    const miltonDai = await func.getValue(keys.ItfMiltonProxyDai);

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
