const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, ItfLiquidator) {

    const miltonUsdt = await func.getValue(keys.ItfMiltonProxyUsdt);
    const miltonStorageUsdt = await func.getValue(keys.MiltonStorageProxyUsdt);

    await deployer.deploy(ItfLiquidator, miltonUsdt, miltonStorageUsdt);
    const itfLiquidatorUsdt = await ItfLiquidator.deployed();

    await func.update(keys.ItfLiquidatorUsdt, itfLiquidatorUsdt.address);
};
