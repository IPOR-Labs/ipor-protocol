const keys = require("./json_keys.js");
const func = require("./json_func.js");

const IvTokenUsdt = artifacts.require("IvTokenUsdt");

module.exports = async function (deployer, _network) {
    const stable = await func.get_value(keys.USDT);

    await deployer.deploy(IvTokenUsdt, "IV USDT", "ivUSDT", stable);
    const ivTokenUsdt = await IvTokenUsdt.deployed();

    await func.update("ivUSDT", ivTokenUsdt.address);
};
