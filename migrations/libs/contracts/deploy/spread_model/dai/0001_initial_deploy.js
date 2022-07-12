const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, MiltonSpreadModelDai) {
    await deployer.deploy(MiltonSpreadModelDai);
    const miltonSpreadModelDai = await MiltonSpreadModelDai.deployed();

    await func.update(keys.MiltonSpreadModelDai, miltonSpreadModelDai.address);
};
