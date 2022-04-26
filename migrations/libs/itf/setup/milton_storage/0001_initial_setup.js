const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

module.exports = async function (deployer, _network, addresses) {
    const josephUsdt = await func.getValue(keys.ItfJosephProxyUsdt);
    const josephUsdc = await func.getValue(keys.ItfJosephProxyUsdc);
    const josephDai = await func.getValue(keys.ItfJosephProxyDai);

    const miltonStorageUsdt = await func.getValue(keys.MiltonStorageProxyUsdt);
    const miltonStorageUsdc = await func.getValue(keys.MiltonStorageProxyUsdc);
    const miltonStorageDai = await func.getValue(keys.MiltonStorageProxyDai);

    const miltonUsdt = await func.getValue(keys.ItfMiltonProxyUsdt);
    const miltonUsdc = await func.getValue(keys.ItfMiltonProxyUsdc);
    const miltonDai = await func.getValue(keys.ItfMiltonProxyDai);

    const miltonStorageUsdtInstance = await MiltonStorageUsdt.at(miltonStorageUsdt);
    const miltonStorageUsdcInstance = await MiltonStorageUsdc.at(miltonStorageUsdc);
    const miltonStorageDaiInstance = await MiltonStorageDai.at(miltonStorageDai);

    await miltonStorageUsdtInstance.setJoseph(josephUsdt);
    await miltonStorageUsdcInstance.setJoseph(josephUsdc);
    await miltonStorageDaiInstance.setJoseph(josephDai);

    await miltonStorageUsdtInstance.setMilton(miltonUsdt);
    await miltonStorageUsdcInstance.setMilton(miltonUsdc);
    await miltonStorageDaiInstance.setMilton(miltonDai);
};
