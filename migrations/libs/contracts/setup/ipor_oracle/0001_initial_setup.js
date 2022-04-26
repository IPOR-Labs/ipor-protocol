const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const IporOracle = artifacts.require("IporOracle");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const iporOracle = await func.get_value(keys.IporOracleProxy);

    const iporOracleInstance = await IporOracle.at(iporOracle);

    await iporOracleInstance.addUpdater(admin);
    await iporOracleInstance.addUpdater(iporIndexAdmin);
};
