require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/deploy/joseph/usdc/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/joseph/usdc/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses);
    } else {
        await script(deployer, _network, addresses);
    }
};
