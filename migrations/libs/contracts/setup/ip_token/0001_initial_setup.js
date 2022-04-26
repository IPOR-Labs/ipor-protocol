const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const IpTokenUsdt = artifacts.require("IpTokenUsdt");
const IpTokenUsdc = artifacts.require("IpTokenUsdc");
const IpTokenDai = artifacts.require("IpTokenDai");

module.exports = async function (deployer, _network, addresses) {
    const josephUsdt = await func.getValue(keys.JosephProxyUsdt);
    const josephUsdc = await func.getValue(keys.JosephProxyUsdc);
    const josephDai = await func.getValue(keys.JosephProxyDai);

    const ipUSDT = await func.getValue(keys.ipUSDT);
    const ipUSDC = await func.getValue(keys.ipUSDC);
    const ipDAI = await func.getValue(keys.ipDAI);

    const ipUsdtInstance = await IpTokenUsdt.at(ipUSDT);
    const ipUsdcInstance = await IpTokenUsdc.at(ipUSDC);
    const ipDaiInstance = await IpTokenDai.at(ipDAI);

    await ipUsdtInstance.setJoseph(josephUsdt);
    await ipUsdcInstance.setJoseph(josephUsdc);
    await ipDaiInstance.setJoseph(josephDai);
};
