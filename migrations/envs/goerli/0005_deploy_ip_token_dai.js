const script = require("../../libs/contracts/deploy/ip_token/dai/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const IpTokenDai = artifacts.require("IpTokenDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IpTokenDai);
    await func.updateLastCompletedMigration();
};
