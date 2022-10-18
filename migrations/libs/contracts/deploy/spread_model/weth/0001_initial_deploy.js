const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, MiltonSpreadModelWeth) {
    await deployer.deploy(MiltonSpreadModelWeth);
    const miltonSpreadModelWeth = await MiltonSpreadModelWeth.deployed();

    await func.update(keys.MiltonSpreadModelWeth, miltonSpreadModelWeth.address);
};
