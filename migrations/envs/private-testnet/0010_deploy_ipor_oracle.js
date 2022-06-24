require("dotenv").config({ path: "../../../.env" });
const keys = require("../../libs/json_keys.js");
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/ipor_oracle/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/ipor_oracle/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_USDT) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_USDT is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_USDC) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_USDC is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_DAI) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_DAI is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_USDT) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_USDT is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_USDC) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_USDC is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_DAI) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_DAI is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_USDT) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_USDT is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_USDC) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_USDC is not set!"
        );
    }

    if (!process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_DAI) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_DAI is not set!"
        );
    }

    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);

    const assets = [usdt, usdc, dai];

    const updateTimestamps = [
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_USDT),
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_USDC),
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_UPDATE_TIMESTAMP_DAI),
    ];
    const exponentialMovingAverages = [
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_USDT),
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_USDC)),
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EMA_DAI),
    ];
    const exponentialWeightedMovingVariances = [
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_USDT),
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_USDC),
        BigInt(process.env.SC_MIGRATION_INITIAL_IPOR_INDEX_EWMVAR_DAI),
    ];

    const initialParams = {
        assets,
        updateTimestamps,
        exponentialMovingAverages,
        exponentialWeightedMovingVariances,
    };

    if (process.env.ITF_ENABLED === "true") {
        const ItfIporOracle = artifacts.require("ItfIporOracle");
        await itfScript(deployer, _network, addresses, ItfIporOracle, initialParams);
    } else {
        const IporOracle = artifacts.require("IporOracle");
        await script(deployer, _network, addresses, IporOracle, initialParams);
    }
    await func.updateLastCompletedMigration();
};
