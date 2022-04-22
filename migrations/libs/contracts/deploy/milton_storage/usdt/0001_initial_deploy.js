const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");

module.exports = async function (deployer, _network, addresses) {
    const miltonStorageProxy = await deployProxy(MiltonStorageUsdt, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageImpl = await erc1967.getImplementationAddress(
        miltonStorageProxy.address
    );

    await func.update(keys.MiltonStorageProxyUsdt, miltonStorageProxy.address);
    await func.update(keys.MiltonStorageImplUsdt, miltonStorageImpl);
};
