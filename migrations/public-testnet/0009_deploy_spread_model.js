const keys = require("./json_keys.js");
const func = require("./json_func.js");

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");

module.exports = async function (deployer, _network) {

    await deployer.deploy(MiltonSpreadModel);
    const miltonSpreadModel = await MiltonSpreadModel.deployed();

    await func.update("MiltonSpreadModel", miltonSpreadModel.address);
};
