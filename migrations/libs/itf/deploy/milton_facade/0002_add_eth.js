const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network) {
    const MiltonFacadeDataProvider = artifacts.require("MiltonFacadeDataProvider");
    const miltonFacadeDataProvider = await MiltonFacadeDataProvider.at(await func.getValue(keys.ItfMiltonFacadeDataProviderProxy));
    const weth = await func.getValue(keys.WETH);
    const miltonWeth = await func.getValue(keys.ItfMiltonProxyWeth);
    const miltonStorageWeth = await func.getValue(keys.MiltonStorageProxyWeth);
    const josephWeth = await func.getValue(keys.ItfJosephProxyWeth);
    await miltonFacadeDataProvider.addAssetConfig(weth, miltonWeth, miltonStorageWeth, josephWeth)
};
