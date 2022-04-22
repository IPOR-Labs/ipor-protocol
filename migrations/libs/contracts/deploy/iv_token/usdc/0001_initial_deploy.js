const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, IvTokenUsdc) {
    const asset = await func.get_value(keys.USDC);

    await deployer.deploy(IvTokenUsdc, "IV USDC", "ivUSDC", asset);
    const ivTokenUsdc = await IvTokenUsdc.deployed();

    await func.update(keys.ivUSDC, ivTokenUsdc.address);
};
