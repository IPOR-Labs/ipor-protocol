const script = require("../../libs/contracts/deploy/ip_token/usdc/0001_initial_deploy.js");

const IpTokenUsdc = artifacts.require("IpTokenUsdc");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IpTokenUsdc);
};
