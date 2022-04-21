const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MiltonStorageDai = artifacts.require("MiltonStorageDai");

module.exports = async function (deployer, _network) {
    const miltonStorageProxyDai = await deployProxy(MiltonStorageDai, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageImplDai = await erc1967.getImplementationAddress(
        miltonStorageProxyDai.address
    );

    await func.update(keys.MiltonStorageProxyDai, miltonStorageProxyDai.address);
    await func.update(keys.MiltonStorageImplDai, miltonStorageImplDai.address);
};
