const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, IpTokenDai) {
    const asset = await func.getValue(keys.DAI);

    await deployer.deploy(IpTokenDai, "IP DAI", "ipDAI", asset);
    const ipTokenDai = await IpTokenDai.deployed();

    await func.update(keys.ipDAI, ipTokenDai.address);
};
