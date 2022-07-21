const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, IporOracle) {
    await deployer.deploy(IporOracle);
    const iporOracleImpl = await IporOracle.deployed();

    await func.update(keys.IporOracleImpl, iporOracleImpl.address);
};
