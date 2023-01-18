const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/faucet/0001_prepare_upgrade_v2.js");

const TestnetFaucet = artifacts.require("TestnetFaucet");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, TestnetFaucet);
    await func.updateLastCompletedMigration();
};
