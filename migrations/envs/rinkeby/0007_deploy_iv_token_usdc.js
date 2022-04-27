const script = require("../../libs/contracts/deploy/iv_token/usdc/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const IvTokenUsdc = artifacts.require("IvTokenUsdc");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IvTokenUsdc);
    await func.updateLastCompletedMigration();
};
