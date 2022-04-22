const script = require("../../libs/contracts/deploy/stanley/usdt/0001_initial_deploy.js");

const StanleyUsdt = artifacts.require("StanleyUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StanleyUsdt);
};
