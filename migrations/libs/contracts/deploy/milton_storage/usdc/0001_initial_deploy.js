const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");

module.exports = async function (deployer, _network) {
    const miltonStorageProxyUsdc = await deployProxy(MiltonStorageUsdc, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageImplUsdc = await erc1967.getImplementationAddress(
        miltonStorageProxyUsdc.address
    );

    await func.update(keys.MiltonStorageProxyUsdc, miltonStorageProxyUsdc.address);
    await func.update(keys.MiltonStorageImplUsdc, miltonStorageImplUsdc.address);
};
