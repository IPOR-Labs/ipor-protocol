const script = require("../../libs/contracts/deploy/ipor_token/dai/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const IporToken = artifacts.require("IporToken");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, IporToken);
    await func.updateLastCompletedMigration();
};
