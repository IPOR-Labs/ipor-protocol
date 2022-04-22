require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/mocks/0002_setup_testnet_strategy.js");
const itfScript = require("../../libs/itf/setup/stanley_strategies/0002_setup_testnet_strategy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network, addresses);
    } else {
        await script(deployer, _network, addresses);
    }
};
