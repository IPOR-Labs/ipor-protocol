const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/setup/faucet/0001_initial_setup.js");

const TestnetFaucet = artifacts.require("TestnetFaucet");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, TestnetFaucet);
	await func.updateLastCompletedMigration();
};
