require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/deploy/joseph/usdt/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/joseph/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfJosephUsdt = artifacts.require("ItfJosephUsdt");
        await itfScript(deployer, _network, addresses, ItfJosephUsdt);
    } else {
        const JosephUsdt = artifacts.require("JosephUsdt");
        await script(deployer, _network, addresses, JosephUsdt);
    }
};
