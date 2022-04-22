require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/deploy/milton/usdt/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/milton/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
        await itfScript(deployer, _network, addresses, ItfMiltonUsdt);
    } else {
        const MiltonUsdt = artifacts.require("MiltonUsdt");
        await script(deployer, _network, addresses, MiltonUsdt);
    }
};
