const script = require("../../libs/contracts/deploy/iv_token/dai/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const IvTokenDai = artifacts.require("IvTokenDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IvTokenDai);
	await func.updateLastCompletedMigration();
};
