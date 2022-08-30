require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley/dai/0002_upgrade_proxy_v2.js");
const itfScript = require("../../libs/itf/upgrade/stanley/dai/0001_upgrade_proxy_v2.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfStanleyDai = artifacts.require("ItfStanleyDai");
        await itfScript(deployer, _network, addresses, ItfStanleyDai);
    } else {
        const StanleyDai = artifacts.require("StanleyDai");
        await script(deployer, _network, addresses, StanleyDai);
    }

    await func.updateLastCompletedMigration();
};
