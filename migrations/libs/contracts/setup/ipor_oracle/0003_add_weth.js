require("dotenv").config({ path: "../../../.env" });

const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");


const IporOracle = artifacts.require("IporOracle");

module.exports = async function (deployer, _network, addresses) {
    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_WETH) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_WETH is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_WETH) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_WETH is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_WETH) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_WETH is not set!"
        );
    }

    const weth = await func.getValue(keys.WETH);

    let iporOracleInstance;
    if (process.env.ITF_ENABLED === "true") {
        const iporOracleAddress = await func.getValue(keys.ItfIporOracleProxy);
        iporOracleInstance = await IporOracle.at(iporOracleAddress);
    } else {
        const iporOracleAddress = await func.getValue(keys.IporOracleProxy);
        iporOracleInstance = await IporOracle.at(iporOracleAddress);
    }

    await iporOracleInstance.addAsset(
        weth,
        process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_WETH,
        process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_WETH,
        process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_WETH
    );
};
