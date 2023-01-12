const func = require("../../libs/json_func.js");
const script = require("../../libs/mocks/0004_deploy_mock_ipor_weighted.js");
const keys = require("../../libs/json_keys.js");
const MockIporWeighted = artifacts.require("MockIporWeighted");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MockIporWeighted);
    if (!process.env.SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS) {
        throw new Error(
            "Transfer ownership failed! Environment parameter SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS is not set!"
        );
    }

    const iporOwnerAddress = process.env.SC_MIGRATION_IPOR_PROTOCOL_OWNER_ADDRESS;
    const iporAlgorithmProxy = await func.getValue(keys.IporAlgorithmProxy);

    const iporWeightedInstance = await MockIporWeighted.at(iporAlgorithmProxy);
    await iporWeightedInstance.transferOwnership(iporOwnerAddress);
    await func.updateLastCompletedMigration();
};