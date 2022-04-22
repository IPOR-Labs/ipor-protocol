const script = require("../../libs/contracts/deploy/milton/usdt/0001_initial_deploy.js");

const MiltonUsdt = artifacts.require("MiltonUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonUsdt);
};
