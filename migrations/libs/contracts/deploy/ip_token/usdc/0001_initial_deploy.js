const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const IpTokenUsdc = artifacts.require("IpTokenUsdc");

module.exports = async function (deployer, _network, addresses) {
    const asset = await func.get_value(keys.USDC);

    await deployer.deploy(IpTokenUsdc, "IP USDC", "ipUSDC", asset);
    const ipTokenUsdc = await IpTokenUsdc.deployed();

    await func.update(keys.ipUSDC, ipTokenUsdc.address);
};
