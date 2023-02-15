const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonStorage) {
    const proxyAddress = await func.getValue(keys.MiltonStorageProxyUsdc);

    const implAddress = await prepareUpgrade(proxyAddress, MiltonStorage, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.MiltonStorageImplUsdc, implAddress);
};
