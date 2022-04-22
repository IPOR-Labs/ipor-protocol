require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/deploy/ipor_oracle_facade/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/ipor_oracle_facade/0001_initial_deploy.js");
const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses, IporOracleFacadeDataProvider);
    } else {
        await script(deployer, _network, addresses, IporOracleFacadeDataProvider);
    }
};
