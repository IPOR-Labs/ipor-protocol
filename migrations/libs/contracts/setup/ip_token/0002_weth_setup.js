const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const IpTokenWeth = artifacts.require("IpTokenWeth");

module.exports = async function (deployer, _network, addresses) {
    const josephWeth = await func.getValue(keys.JosephProxyWeth);
    const ipWETH = await func.getValue(keys.ipWETH);
    const ipWethInstance = await IpTokenWeth.at(ipWETH);
    await ipWethInstance.setJoseph(josephWeth);
};
