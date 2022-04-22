require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/setup/iv_token/0001_initial_setup.js");
const itfScript = require("../../libs/itf/setup/iv_token/0001_initial_setup.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses);
    } else {
        await script(deployer, _network, addresses);
    }
};
