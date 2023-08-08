require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const keys = require("../../libs/json_keys.js");

const StrategyDsrDai = artifacts.require("StrategyDsrDai");

module.exports = async function (deployer, _network, addresses) {
    if (!process.env.SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS) {
        throw new Error(
            "Transfer ownership failed! Environment parameter SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS is not set!"
        );
    }

    const iporOwnerAddress = process.env.SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS;

    const dsrStrategyProxyDai = await func.getValue(keys.DsrStrategyProxyDai);
    const dsrStrategyDaiInstance = await StrategyDsrDai.at(dsrStrategyProxyDai);

    await dsrStrategyDaiInstance.transferOwnership(iporOwnerAddress);

    await func.updateLastCompletedMigration();
};
