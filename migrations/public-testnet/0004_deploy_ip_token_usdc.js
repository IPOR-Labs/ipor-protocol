const keys = require("./json_keys.js");
const func = require("./json_func.js");

const IpTokenUsdc = artifacts.require("IpTokenUsdc");

module.exports = async function (deployer, _network) {
    const stable = await func.get_value(keys.USDC);

    await deployer.deploy(IpTokenUsdc, "IP USDC", "ipUSDC", stable);
    const ipTokenUsdc = await IpTokenUsdc.deployed();

    await func.update("ipUSDC", ipTokenUsdc.address);
};
