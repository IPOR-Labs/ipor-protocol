const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, ItfMiltonSpreadModel) {
    await deployer.deploy(ItfMiltonSpreadModel);
    const itfMiltonSpreadModel = await ItfMiltonSpreadModel.deployed();

    await func.update(keys.ItfMiltonSpreadModel, itfMiltonSpreadModel.address);
};
