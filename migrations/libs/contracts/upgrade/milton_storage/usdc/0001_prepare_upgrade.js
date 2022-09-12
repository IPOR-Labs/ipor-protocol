const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonStorageUsdc) {
    const miltonStorageProxyAddress = await func.getValue(keys.MiltonStorageProxyUsdc);

    const miltonStorageImplAddress = await prepareUpgrade(
        miltonStorageProxyAddress,
        MiltonStorageUsdc,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.MiltonStorageImplUsdc, miltonStorageImplAddress);
};
