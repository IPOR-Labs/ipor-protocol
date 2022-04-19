const keys = require("./json_keys.js");
const func = require("./json_func.js");

const IvTokenUsdc = artifacts.require("IvTokenUsdc");

module.exports = async function (deployer, _network) {
    const stable = await func.get_value(keys.USDC);

    await deployer.deploy(IvTokenUsdc, "IV USDC", "ivUSDC", stable);
    const ivTokenUsdc = await IvTokenUsdc.deployed();

    await func.update("ivUSDC", ivTokenUsdc.address);
};
