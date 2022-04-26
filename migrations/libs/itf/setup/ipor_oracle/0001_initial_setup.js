const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const ItfIporOracle = artifacts.require("ItfIporOracle");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const iporOracle = await func.get_value(keys.ItfIporOracleProxy);

    const iporOracleInstance = await ItfIporOracle.at(iporOracle);

    await iporOracleInstance.addUpdater(admin);
    await iporOracleInstance.addUpdater(iporIndexAdmin);
};
