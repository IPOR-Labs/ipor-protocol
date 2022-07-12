const script = require("../../libs/contracts/deploy/milton/dai/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");
const MiltonDai = artifacts.require("MiltonDai");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonDai);
    await func.updateLastCompletedMigration();
};
