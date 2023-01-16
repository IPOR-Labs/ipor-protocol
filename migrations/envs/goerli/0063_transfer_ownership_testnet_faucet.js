require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const keys = require("../../libs/json_keys.js");

const TestnetFaucet = artifacts.require("TestnetFaucet");

module.exports = async function (deployer, _network, addresses) {
    if (!process.env.SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS) {
        throw new Error(
            "Transfer ownership failed! Environment parameter SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS is not set!"
        );
    }

    const iporOwnerAddress = process.env.SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS;

    // IP Token
    const testnetFaucetProxyAddress = await func.getValue(keys.TestnetFaucetProxy);

    const testnetFaucetProxy = await TestnetFaucet.at(testnetFaucetProxyAddress);

    await testnetFaucetProxy.transferOwnership(iporOwnerAddress);

    await func.updateLastCompletedMigration();
};
