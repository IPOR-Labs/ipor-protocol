require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley/usdc/0002_upgrade_proxy_v2.js");
const itfScript = require("../../libs/itf/upgrade/stanley/usdc/0001_upgrade_proxy_v2.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfStanleyUsdc = artifacts.require("ItfStanleyUsdc");
        await itfScript(deployer, _network, addresses, ItfStanleyUsdc);
    } else {
        const StanleyUsdc = artifacts.require("StanleyUsdc");
        await script(deployer, _network, addresses, StanleyUsdc);
    }

    await func.updateLastCompletedMigration();
};
