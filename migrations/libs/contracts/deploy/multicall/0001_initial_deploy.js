const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, Multicall) {

    await deployer.deploy(Multicall);
    const multicall = await Multicall.deployed();

    await func.update(keys.Multicall, multicall.address);
};
