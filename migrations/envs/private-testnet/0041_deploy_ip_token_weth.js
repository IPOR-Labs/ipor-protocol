const script = require("../../libs/contracts/deploy/ip_token/usdt/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const IpTokenWeth = artifacts.require("IpTokenWeth");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IpTokenWeth);
	await func.updateLastCompletedMigration();
};
