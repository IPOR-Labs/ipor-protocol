const func = require("../../libs/json_func.js");
const script = require("../../libs/mocks/0004_deploy_mock_ipor_weighted.js");
const keys = require("../../libs/json_keys.js");
const IporOracle = artifacts.require("IporOracle");
const MockIporWeighted = artifacts.require("MockIporWeighted");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MockIporWeighted);
    const iporAlgorithmProxy = await func.getValue(keys.IporAlgorithmProxy);
    let iporOracleProxyAddress;
    if (process.env.ITF_ENABLED === "true") {
        iporOracleProxyAddress = await func.getValue(keys.ItfIporOracleProxy);
    } else {
        iporOracleProxyAddress = await func.getValue(keys.IporOracleProxy);
    }

    const iporOracleInstance = await IporOracle.at(iporOracleProxyAddress);
    await iporOracleInstance.setIporAlgorithmFacade(iporAlgorithmProxy);
    await func.updateLastCompletedMigration();
};
