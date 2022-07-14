require("dotenv").config({ path: "../../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

module.exports = async function (deployer, _network, addresses) {
    const josephUsdt = await func.getValue(keys.JosephProxyUsdt);
    const josephUsdc = await func.getValue(keys.JosephProxyUsdc);
    const josephDai = await func.getValue(keys.JosephProxyDai);

    const stanleyUsdt = await func.getValue(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.getValue(keys.StanleyProxyUsdc);
    const stanleyDai = await func.getValue(keys.StanleyProxyDai);

    const miltonUsdt = await func.getValue(keys.MiltonProxyUsdt);
    const miltonUsdc = await func.getValue(keys.MiltonProxyUsdc);
    const miltonDai = await func.getValue(keys.MiltonProxyDai);

    const miltonUsdtInstance = await MiltonUsdt.at(miltonUsdt);
    const miltonUsdcInstance = await MiltonUsdc.at(miltonUsdc);
    const miltonDaiInstance = await MiltonDai.at(miltonDai);

    if (process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON) {
        await miltonUsdtInstance.unpause();
        await miltonUsdtInstance.setJoseph(josephUsdt);
        await miltonUsdtInstance.setupMaxAllowanceForAsset(josephUsdt);
        await miltonUsdtInstance.setupMaxAllowanceForAsset(stanleyUsdt);
        await miltonUsdtInstance.pause();

        await miltonUsdcInstance.unpause();
        await miltonUsdcInstance.setJoseph(josephUsdc);
        await miltonUsdcInstance.setupMaxAllowanceForAsset(josephUsdc);
        await miltonUsdcInstance.setupMaxAllowanceForAsset(stanleyUsdc);
        await miltonUsdcInstance.pause();

        await miltonDaiInstance.unpause();
        await miltonDaiInstance.setJoseph(josephDai);
        await miltonDaiInstance.setupMaxAllowanceForAsset(josephDai);
        await miltonDaiInstance.setupMaxAllowanceForAsset(stanleyDai);
        await miltonDaiInstance.pause();
    } else {
        await miltonUsdtInstance.setJoseph(josephUsdt);
        await miltonUsdcInstance.setJoseph(josephUsdc);
        await miltonDaiInstance.setJoseph(josephDai);

        await miltonUsdtInstance.setupMaxAllowanceForAsset(josephUsdt);
        await miltonUsdcInstance.setupMaxAllowanceForAsset(josephUsdc);
        await miltonDaiInstance.setupMaxAllowanceForAsset(josephDai);

        await miltonUsdtInstance.setupMaxAllowanceForAsset(stanleyUsdt);
        await miltonUsdcInstance.setupMaxAllowanceForAsset(stanleyUsdc);
        await miltonDaiInstance.setupMaxAllowanceForAsset(stanleyDai);
    }
};
