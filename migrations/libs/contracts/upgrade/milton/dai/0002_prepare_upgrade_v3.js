const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, Milton) {
    const proxyAddress = await func.getValue(keys.MiltonProxyDai);

    const implAddress = await prepareUpgrade(proxyAddress, Milton, {
        deployer: deployer,
        kind: "uups",
    });

    await func.update(keys.MiltonImplDai, implAddress);
};
