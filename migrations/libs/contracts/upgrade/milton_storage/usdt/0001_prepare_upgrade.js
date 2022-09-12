const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonStorageUsdt) {
    const miltonStorageProxyAddress = await func.getValue(keys.MiltonStorageProxyUsdt);

    const miltonStorageImplAddress = await prepareUpgrade(
        miltonStorageProxyAddress,
        MiltonStorageUsdt,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.MiltonStorageImplUsdt, miltonStorageImplAddress);
};
