const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, ItfMiltonSpreadModelUsdt) {
    await deployer.deploy(ItfMiltonSpreadModelUsdt);
    const itfMiltonSpreadModelUsdt = await ItfMiltonSpreadModelUsdt.deployed();

    await func.update(keys.ItfMiltonSpreadModelUsdt, itfMiltonSpreadModelUsdt.address);
};
