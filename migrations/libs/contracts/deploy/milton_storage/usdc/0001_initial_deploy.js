const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonStorageUsdc) {
    const miltonStorageProxy = await deployProxy(MiltonStorageUsdc, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageImpl = await erc1967.getImplementationAddress(miltonStorageProxy.address);

    await func.update(keys.MiltonStorageProxyUsdc, miltonStorageProxy.address);
    await func.update(keys.MiltonStorageImplUsdc, miltonStorageImpl);
};
