const script = require("../../libs/contracts/deploy/spread_model/dai/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    const MiltonSpreadModelDai = artifacts.require("MiltonSpreadModelDai");
    await script(deployer, _network, addresses, MiltonSpreadModelDai);
    await func.updateLastCompletedMigration();
};
