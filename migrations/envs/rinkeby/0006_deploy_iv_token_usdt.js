const script = require("../../libs/contracts/deploy/iv_token/usdt/0001_initial_deploy.js");

const IvTokenUsdt = artifacts.require("IvTokenUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IvTokenUsdt);
};
