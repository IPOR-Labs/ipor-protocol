require("dotenv").config({ path: "../../../.env" });
const script = require("../../libs/contracts/deploy/milton/dai/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/milton/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        const ItfMiltonDai = artifacts.require("ItfMiltonDai");
        await itfScript(deployer, _network, addresses, ItfMiltonDai);
    } else {
        const MiltonDai = artifacts.require("MiltonDai");
        await script(deployer, _network, addresses, MiltonDai);
    }
};
