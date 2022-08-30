const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, Stanley) {
    const stanleyProxyAddress = await func.getValue(keys.StanleyProxyUsdc);

    const stanleyImplAddress = await upgradeProxy(stanleyProxyAddress, Stanley);

    await func.update(keys.StanleyImplUsdc, stanleyImplAddress);
};
