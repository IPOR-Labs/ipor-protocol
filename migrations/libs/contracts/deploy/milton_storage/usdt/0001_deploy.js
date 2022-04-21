const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");

module.exports = async function (deployer, _network) {
    const miltonStorageProxyUsdt = await deployProxy(MiltonStorageUsdt, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageImplUsdt = await erc1967.getImplementationAddress(
        miltonStorageProxyUsdt.address
    );

    await func.update(keys.MiltonStorageProxyUsdt, miltonStorageProxyUsdt.address);
    await func.update(keys.MiltonStorageImplUsdt, miltonStorageImplUsdt.address);
};
