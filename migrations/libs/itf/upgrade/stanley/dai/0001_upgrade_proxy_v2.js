const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { upgradeProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, Stanley) {
    const stanleyProxyAddress = await func.getValue(keys.ItfStanleyProxyDai);

    await upgradeProxy(stanleyProxyAddress, Stanley);

    const implAddress = await erc1967.getImplementationAddress(stanleyProxyAddress);

    await func.update(keys.ItfStanleyImplDai, implAddress);
};
