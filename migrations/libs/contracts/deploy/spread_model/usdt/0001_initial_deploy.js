const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, MiltonSpreadModelUsdt) {
    await deployer.deploy(MiltonSpreadModelUsdt);
    const miltonSpreadModelUsdt = await MiltonSpreadModelUsdt.deployed();

    await func.update(keys.MiltonSpreadModelUsdt, miltonSpreadModelUsdt.address);
};
