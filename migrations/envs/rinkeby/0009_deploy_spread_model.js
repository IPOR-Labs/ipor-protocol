const scriptUsdt = require("../../libs/contracts/deploy/spread_model/usdt/0001_initial_deploy.js");
const scriptUsdc = require("../../libs/contracts/deploy/spread_model/usdc/0001_initial_deploy.js");
const scriptDai = require("../../libs/contracts/deploy/spread_model/dai/0001_initial_deploy.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    const MiltonSpreadModelUsdt = artifacts.require("MiltonSpreadModelUsdt");
    await scriptUsdt(deployer, _network, addresses, MiltonSpreadModelUsdt);

    const MiltonSpreadModelUsdc = artifacts.require("MiltonSpreadModelUsdc");
    await scriptUsdc(deployer, _network, addresses, MiltonSpreadModelUsdc);

    const MiltonSpreadModelDai = artifacts.require("MiltonSpreadModelDai");
    await scriptDai(deployer, _network, addresses, MiltonSpreadModelDai);

    await func.updateLastCompletedMigration();
};
