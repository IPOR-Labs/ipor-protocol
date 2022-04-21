const keys = require("./json_keys.js");
const func = require("./json_func.js");

const IvTokenDai = artifacts.require("IvTokenDai");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.DAI);

    await deployer.deploy(IvTokenDai, "IV DAI", "ivDAI", asset);
    const ivTokenDai = await IvTokenDai.deployed();

    await func.update(keys.ivDAI, ivTokenDai.address);
};
