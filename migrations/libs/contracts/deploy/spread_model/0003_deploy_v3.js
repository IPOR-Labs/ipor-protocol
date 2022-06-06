const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, MiltonSpreadModelV3) {
    await deployer.deploy(MiltonSpreadModelV3);
    const miltonSpreadModelV3 = await MiltonSpreadModelV3.deployed();

    await func.update(keys.MiltonSpreadModel, miltonSpreadModelV3.address);
};
