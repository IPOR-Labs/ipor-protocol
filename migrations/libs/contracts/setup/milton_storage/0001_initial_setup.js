const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

module.exports = async function (deployer, _network, addresses) {
    const josephUsdt = await func.get_value(keys.JosephProxyUsdt);
    const josephUsdc = await func.get_value(keys.JosephProxyUsdc);
    const josephDai = await func.get_value(keys.JosephProxyDai);

    const miltonStorageUsdt = await func.get_value(keys.MiltonStorageProxyUsdt);
    const miltonStorageUsdc = await func.get_value(keys.MiltonStorageProxyUsdc);
    const miltonStorageDai = await func.get_value(keys.MiltonStorageProxyDai);

    const miltonUsdt = await func.get_value(keys.MiltonProxyUsdt);
    const miltonUsdc = await func.get_value(keys.MiltonProxyUsdc);
    const miltonDai = await func.get_value(keys.MiltonProxyDai);

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
