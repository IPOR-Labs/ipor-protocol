const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, ItfMiltonSpreadModelUsdc) {
    await deployer.deploy(ItfMiltonSpreadModelUsdc);
    const itfMiltonSpreadModelUsdc = await ItfMiltonSpreadModelUsdc.deployed();

    await func.update(keys.ItfMiltonSpreadModelUsdc, itfMiltonSpreadModelUsdc.address);
};
