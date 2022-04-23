const script = require("../../libs/contracts/deploy/stanley/dai/0001_initial_deploy.js");

const StanleyDai = artifacts.require("StanleyDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, StanleyDai);
};
