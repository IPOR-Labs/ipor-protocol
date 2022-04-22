require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/setup/ipor_oracle/0001_initial_setup.js");
const itfScript = require("../../libs/itf/setup/ipor_oracle/0001_initial_setup.js");
const itfScriptInitIporValues = require("../../libs/itf/setup/ipor_oracle/0002_initial_ipor_values.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses);

        if (process.env.INITIAL_IPOR_MIGRATION_ENABLED === "true") {
            await itfScriptInitIporValues(deployer, _network, addresses);
        }
    } else {
        await script(deployer, _network, addresses);
    }
};
