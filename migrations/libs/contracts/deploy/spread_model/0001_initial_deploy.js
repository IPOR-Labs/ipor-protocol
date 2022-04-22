const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");

module.exports = async function (deployer, _network, addresses) {

    await deployer.deploy(MiltonSpreadModel);
    const miltonSpreadModel = await MiltonSpreadModel.deployed();

    await func.update(keys.MiltonSpreadModel, miltonSpreadModel.address);
};
