const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, ItfLiquidator) {

    const miltonUsdc = await func.getValue(keys.ItfMiltonProxyUsdc);
    const miltonStorageUsdc = await func.getValue(keys.MiltonStorageProxyUsdc);

    await deployer.deploy(ItfLiquidator, [miltonUsdc, miltonStorageUsdc]);
    const itfLiquidatorUsdc = await ItfLiquidator.deployed();

    await func.update(keys.ItfLiquidatorUsdc, itfLiquidatorUsdc.address);
};
