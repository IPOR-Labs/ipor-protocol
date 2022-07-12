const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, MiltonSpreadModelUsdc) {
    await deployer.deploy(MiltonSpreadModelUsdc);
    const miltonSpreadModelUsdc = await MiltonSpreadModelUsdc.deployed();

    await func.update(keys.MiltonSpreadModelUsdc, miltonSpreadModelUsdc.address);
};
