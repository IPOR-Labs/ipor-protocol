const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, ItfMiltonSpreadModelDai) {
    await deployer.deploy(ItfMiltonSpreadModelDai);
    const itfMiltonSpreadModelDai = await ItfMiltonSpreadModelDai.deployed();

    await func.update(keys.ItfMiltonSpreadModelDai, itfMiltonSpreadModelDai.address);
};
