const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade, forceImport } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, Milton) {
    const proxyAddress = await func.getValue(keys.MiltonProxyUsdt);
    const oldImplAddress = await func.getValue(keys.MiltonImplUsdt);

    await forceImport(proxyAddress, oldImplAddress, {
        deployer: deployer,
        kind: "uups",
    });

    const implAddress = await prepareUpgrade(proxyAddress, Milton, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.MiltonImplUsdt, implAddress);
};
