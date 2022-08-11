const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

module.exports = async function (deployer, _network, addresses) {
    const miltonUsdt = await func.getValue(keys.MiltonProxyUsdt);
    const miltonUsdc = await func.getValue(keys.MiltonProxyUsdc);
    const miltonDai = await func.getValue(keys.MiltonProxyDai);

    const miltonUsdtInstance = await MiltonUsdt.at(miltonUsdt);
    const miltonUsdcInstance = await MiltonUsdc.at(miltonUsdc);
    const miltonDaiInstance = await MiltonDai.at(miltonDai);

    await miltonUsdtInstance.pause();
    await miltonUsdcInstance.pause();
    await miltonDaiInstance.pause();
};
