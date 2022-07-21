require("dotenv").config({ path: "../../../.env" });
const keys = require("../../libs/json_keys.js");
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/ipor_oracle/0002_implementation_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const IporOracle = artifacts.require("IporOracle");
    await script(deployer, _network, IporOracle);
    await func.updateLastCompletedMigration();
};
