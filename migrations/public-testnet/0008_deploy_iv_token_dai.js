const keys = require("./json_keys.js");
const func = require("./json_func.js");

const IvTokenDai = artifacts.require("IvTokenDai");

module.exports = async function (deployer, _network) {
    const stable = await func.get_value(keys.DAI);

    await deployer.deploy(IvTokenDai, "IV DAI", "ivDAI", stable);
    const ivTokenDai = await IvTokenDai.deployed();

    await func.update("ivDAI", ivTokenDai.address);
};
