require("dotenv").config({ path: "../../../.env" });

const script = require("../../libs/contracts/deploy/ipor_oracle/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/ipor_oracle/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfIporOracle = artifacts.require("ItfIporOracle");
        await itfScript(deployer, _network, addresses, ItfIporOracle);
    } else {
        const IporOracle = artifacts.require("IporOracle");
        await script(deployer, _network, addresses, IporOracle);
    }
};
