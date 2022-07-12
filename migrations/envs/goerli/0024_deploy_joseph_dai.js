const script = require("../../libs/contracts/deploy/joseph/dai/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const JosephDai = artifacts.require("JosephDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, JosephDai);
    await func.updateLastCompletedMigration();
};
