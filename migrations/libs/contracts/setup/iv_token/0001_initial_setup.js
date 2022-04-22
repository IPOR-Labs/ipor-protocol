const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const IvTokenUsdt = artifacts.require("IvTokenUsdt");
const IvTokenUsdc = artifacts.require("IvTokenUsdc");
const IvTokenDai = artifacts.require("IvTokenDai");

module.exports = async function (deployer, _network,addresses) {
    const stanleyUsdt = await func.get_value(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.get_value(keys.StanleyProxyUsdc);
    const stanleyDai = await func.get_value(keys.StanleyProxyDai);

    const ivUSDT = await func.get_value(keys.ivUSDT);
    const ivUSDC = await func.get_value(keys.ivUSDC);
    const ivDAI = await func.get_value(keys.ivDAI);

    const ivUsdtInstance = await IvTokenUsdt.at(ivUSDT);
    const ivUsdcInstance = await IvTokenUsdc.at(ivUSDC);
    const ivDaiInstance = await IvTokenDai.at(ivDAI);

    await ivUsdtInstance.setStanley(stanleyUsdt);
    await ivUsdcInstance.setStanley(stanleyUsdc);
    await ivDaiInstance.setStanley(stanleyDai);
};
