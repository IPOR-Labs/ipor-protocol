const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonStorageDai) {
    const miltonStorageProxyAddress = await func.getValue(keys.MiltonStorageProxyDai);

    const miltonStorageImplAddress = await prepareUpgrade(
        miltonStorageProxyAddress,
        MiltonStorageDai,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.MiltonStorageImplDai, miltonStorageImplAddress);
};
