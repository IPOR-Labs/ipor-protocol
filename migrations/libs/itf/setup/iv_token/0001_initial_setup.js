const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const IvTokenUsdt = artifacts.require("IvTokenUsdt");
const IvTokenUsdc = artifacts.require("IvTokenUsdc");
const IvTokenDai = artifacts.require("IvTokenDai");

module.exports = async function (deployer, _network, addresses) {
    const stanleyUsdt = await func.getValue(keys.ItfStanleyProxyUsdt);
    const stanleyUsdc = await func.getValue(keys.ItfStanleyProxyUsdc);
    const stanleyDai = await func.getValue(keys.ItfStanleyProxyDai);

    const ivUSDT = await func.getValue(keys.ivUSDT);
    const ivUSDC = await func.getValue(keys.ivUSDC);
    const ivDAI = await func.getValue(keys.ivDAI);

    const ivUsdtInstance = await IvTokenUsdt.at(ivUSDT);
    const ivUsdcInstance = await IvTokenUsdc.at(ivUSDC);
    const ivDaiInstance = await IvTokenDai.at(ivDAI);

    await ivUsdtInstance.setStanley(stanleyUsdt);
    await ivUsdcInstance.setStanley(stanleyUsdc);
    await ivDaiInstance.setStanley(stanleyDai);
};
