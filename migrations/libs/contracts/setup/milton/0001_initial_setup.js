const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

module.exports = async function (deployer, _network) {
    const josephUsdt = await func.get_value(keys.JosephProxyUsdt);
    const josephUsdc = await func.get_value(keys.JosephProxyUsdc);
    const josephDai = await func.get_value(keys.JosephProxyDai);

    const stanleyUsdt = await func.get_value(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.get_value(keys.StanleyProxyUsdc);
    const stanleyDai = await func.get_value(keys.StanleyProxyDai);

    const miltonUsdt = await func.get_value(keys.MiltonProxyUsdt);
    const miltonUsdc = await func.get_value(keys.MiltonProxyUsdc);
    const miltonDai = await func.get_value(keys.MiltonProxyDai);

    const miltonUsdtInstance = await MiltonUsdt.at(miltonUsdt);
    const miltonUsdcInstance = await MiltonUsdc.at(miltonUsdc);
    const miltonDaiInstance = await MiltonDai.at(miltonDai);

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
