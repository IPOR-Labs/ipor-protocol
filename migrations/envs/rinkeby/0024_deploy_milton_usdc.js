const script = require("../../libs/contracts/deploy/milton/usdc/0001_initial_deploy.js");

const MiltonUsdc = artifacts.require("MiltonUsdc");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonUsdc);
};
