const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, IpTokenUsdc) {
    const asset = await func.getValue(keys.USDC);

    await deployer.deploy(IpTokenUsdc, "IP USDC", "ipUSDC", asset);
    const ipTokenUsdc = await IpTokenUsdc.deployed();

    await func.update(keys.ipUSDC, ipTokenUsdc.address);
};
