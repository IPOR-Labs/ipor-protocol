const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, IporOracle) {
    const proxyAddress = await func.getValue(keys.IporOracleProxy);

    const implAddress = await prepareUpgrade(proxyAddress, IporOracle, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.IporOracleImpl, implAddress);
};
