const func = require("../../libs/json_func.js");
const script = require("../../libs/mocks/0004_deploy_mock_ipor_weighted.js");
const keys = require("../../libs/json_keys.js");
const IporOracle = artifacts.require("IporOracle");
const MockIporWeighted = artifacts.require("MockIporWeighted");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MockIporWeighted);
    const iporOracleProxyAddress = await func.getValue(keys.IporOracleProxy);
    const iporAlgorithmProxy = await func.getValue(keys.IporAlgorithmProxy);

    const iporOracleInstance = await IporOracle.at(iporOracleProxyAddress);
    await iporOracleInstance.setAlgorithmAddress(iporAlgorithmProxy);
    await func.updateLastCompletedMigration();
};