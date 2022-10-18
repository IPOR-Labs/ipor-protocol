require("dotenv").config({ path: "../../../.env" });

const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");


const CockpitDataProvider = artifacts.require("CockpitDataProvider");

module.exports = async function (deployer, _network, addresses) {

    const weth = await func.getValue(keys.WETH);

    let cockpitDataProviderAddress;
    if (process.env.ITF_ENABLED === "true") {
        cockpitDataProviderAddress= await func.getValue(keys.ItfCockpitDataProviderProxy);

    } else {
        cockpitDataProviderAddress= await func.getValue(keys.CockpitDataProviderProxy);
    }

    const cockpitDataProviderInstance = await CockpitDataProvider.at(cockpitDataProviderAddress);

    await cockpitDataProviderInstance.addAsset(
        weth
    );
};
