const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MiltonStorageDai = artifacts.require("MiltonStorageDai");

module.exports = async function (deployer, _network, addresses) {
    const miltonStorageProxy = await deployProxy(MiltonStorageDai, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageImpl = await erc1967.getImplementationAddress(
        miltonStorageProxy.address
    );

    await func.update(keys.MiltonStorageProxyDai, miltonStorageProxy.address);
    await func.update(keys.MiltonStorageImplDai, miltonStorageImpl);
};
