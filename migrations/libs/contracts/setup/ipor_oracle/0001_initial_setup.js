const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const IporOracle = artifacts.require("IporOracle");

module.exports = async function (deployer, _network, addresses) {
    const [admin, _] = addresses;

    if (!process.env.SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS is not set!"
        );
    }
    const iporIndexUpdater = process.env.SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS;

    const iporOracle = await func.getValue(keys.IporOracleProxy);

    const iporOracleInstance = await IporOracle.at(iporOracle);

    await iporOracleInstance.addUpdater(admin);
    await iporOracleInstance.addUpdater(iporIndexUpdater);
};
