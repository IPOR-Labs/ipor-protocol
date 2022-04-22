const script = require("../../libs/contracts/deploy/joseph/usdt/0001_initial_deploy.js");

const JosephUsdt = artifacts.require("JosephUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, JosephUsdt);
};
