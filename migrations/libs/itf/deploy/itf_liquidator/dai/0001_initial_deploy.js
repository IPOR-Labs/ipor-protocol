const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, ItfLiquidator) {

    const miltonDai = await func.getValue(keys.ItfMiltonProxyDai);
    const miltonStorageDai = await func.getValue(keys.MiltonStorageProxyDai);

    await deployer.deploy(ItfLiquidator, miltonDai, miltonStorageDai);
    const itfLiquidatorDai = await ItfLiquidator.deployed();

    await func.update(keys.ItfLiquidatorDai, itfLiquidatorDai.address);
};
