const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, ItfMiltonSpreadModelWeth) {
    await deployer.deploy(ItfMiltonSpreadModelWeth);
    const itfMiltonSpreadModelWeth = await ItfMiltonSpreadModelWeth.deployed();

    await func.update(keys.ItfMiltonSpreadModelWeth, itfMiltonSpreadModelWeth.address);
};
