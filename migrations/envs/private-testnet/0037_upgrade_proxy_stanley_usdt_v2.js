require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley/usdt/0002_upgrade_proxy_v2.js");
const itfScript = require("../../libs/itf/upgrade/stanley/usdt/0001_upgrade_proxy_v2.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfStanleyUsdt = artifacts.require("ItfStanleyUsdt");
        await itfScript(deployer, _network, addresses, ItfStanleyUsdt);
    } else {
        const StanleyUsdt = artifacts.require("StanleyUsdt");
        await script(deployer, _network, addresses, StanleyUsdt);
    }

    await func.updateLastCompletedMigration();
};
