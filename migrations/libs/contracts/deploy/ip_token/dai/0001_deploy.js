const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const IpTokenDai = artifacts.require("IpTokenDai");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.DAI);

    await deployer.deploy(IpTokenDai, "IP DAI", "ipDAI", asset);
    const ipTokenDai = await IpTokenDai.deployed();

    await func.update(keys.ipDAI, ipTokenDai.address);
};
