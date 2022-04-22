const script = require("../../libs/contracts/deploy/ip_token/usdt/0001_initial_deploy.js");

const IpTokenUsdt = artifacts.require("IpTokenUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IpTokenUsdt);
};
