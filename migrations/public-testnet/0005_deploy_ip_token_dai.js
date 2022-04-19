const keys = require("./json_keys.js");
const func = require("./json_func.js");

const IpTokenDai = artifacts.require("IpTokenDai");

module.exports = async function (deployer, _network) {
    const stable = await func.get_value(keys.DAI);

    await deployer.deploy(IpTokenDai, "IP DAI", "ipDAI", stable);
    const ipTokenDai = await IpTokenDai.deployed();

    await func.update("ipDAI", ipTokenDai.address);
};
