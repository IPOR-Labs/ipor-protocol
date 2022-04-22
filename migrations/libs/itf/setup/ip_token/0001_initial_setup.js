const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const IpTokenUsdt = artifacts.require("IpTokenUsdt");
const IpTokenUsdc = artifacts.require("IpTokenUsdc");
const IpTokenDai = artifacts.require("IpTokenDai");

module.exports = async function (deployer, _network) {
    const josephUsdt = await func.get_value(keys.ItfJosephProxyUsdt);
    const josephUsdc = await func.get_value(keys.ItfJosephProxyUsdc);
    const josephDai = await func.get_value(keys.ItfJosephProxyDai);

    const ipUSDT = await func.get_value(keys.ipUSDT);
    const ipUSDC = await func.get_value(keys.ipUSDC);
    const ipDAI = await func.get_value(keys.ipDAI);

    const ipUsdtInstance = await IpTokenUsdt.at(ipUSDT);
    const ipUsdcInstance = await IpTokenUsdc.at(ipUSDC);
    const ipDaiInstance = await IpTokenDai.at(ipDAI);

    await ipUsdtInstance.setJoseph(josephUsdt);
    await ipUsdcInstance.setJoseph(josephUsdc);
    await ipDaiInstance.setJoseph(josephDai);
};
