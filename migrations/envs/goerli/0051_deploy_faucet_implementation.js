const { exit } = require("process");
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/faucet/0001_deploy_faucet_implementation.js");

const TestnetFaucet = artifacts.require("TestnetFaucet");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, TestnetFaucet);
    await func.updateLastCompletedMigration();
};
