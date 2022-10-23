require("dotenv").config({ path: "../../../.env" });

const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");


const CockpitDataProvider = artifacts.require("CockpitDataProvider");

module.exports = async function (deployer, _network, addresses) {

    const weth = await func.getValue(keys.WETH);

    let cockpitDataProviderAddress;
    let miltonAddress;
    let josephAddress;
    const miltonStorageAddress = await func.getValue(keys.MiltonStorageProxyWeth);
    const ipTokenAddress = await func.getValue(keys.ipWETH);
    const ivTokenAddress = await func.getValue(keys.ivWETH);
    if (process.env.ITF_ENABLED === "true") {
        cockpitDataProviderAddress= await func.getValue(keys.ItfCockpitDataProviderProxy);
        miltonAddress= await func.getValue(keys.ItfMiltonProxyWeth);
        josephAddress= await func.getValue(keys.ItfJosephProxyWeth);
    } else {
        cockpitDataProviderAddress= await func.getValue(keys.CockpitDataProviderProxy);
        miltonAddress= await func.getValue(keys.MiltonProxyWeth);
        josephAddress= await func.getValue(keys.JosephProxyWeth);

    }
// , address milton, address miltonStorage, address joseph, address ipToken, address ivToken
    const cockpitDataProviderInstance = await CockpitDataProvider.at(cockpitDataProviderAddress);

    await cockpitDataProviderInstance.addAsset(
        weth,
        miltonAddress,
        miltonStorageAddress,
        josephAddress,
        ipTokenAddress,
        ivTokenAddress
    );
};
