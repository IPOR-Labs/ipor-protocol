const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, MiltonSpreadModelV2) {
    await deployer.deploy(MiltonSpreadModelV2);
    const miltonSpreadModelV2 = await MiltonSpreadModelV2.deployed();

    await func.update(keys.MiltonSpreadModel, miltonSpreadModelV2.address);
};
