const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, MiltonSpreadModel) {
    await deployer.deploy(MiltonSpreadModel);
    const miltonSpreadModel = await MiltonSpreadModel.deployed();

    await func.update(keys.MiltonSpreadModel, miltonSpreadModel.address);
};
