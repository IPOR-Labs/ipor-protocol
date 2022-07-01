const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, IporToken) {
    await deployer.deploy(IporToken, "IPOR Token", "IPOR");
    const iporToken = await IporToken.deployed();

    await func.update(keys.IPOR, iporToken.address);
};
