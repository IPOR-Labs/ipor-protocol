const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, Joseph) {
    const proxyAddress = await func.getValue(keys.JosephProxyDai);

    const implAddress = await prepareUpgrade(proxyAddress, Joseph, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.JosephImplDai, implAddress);
};
