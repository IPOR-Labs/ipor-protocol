require("dotenv").config({ path: "../../../.env" });
const keys = require("../../libs/json_keys.js");
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/ipor_oracle/0001_initial_deploy.js");
const itfScript = require("../../libs/itf/deploy/ipor_oracle/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const usdt = await func.get_value(keys.USDT);
    const usdc = await func.get_value(keys.USDC);
    const dai = await func.get_value(keys.DAI);

    const assets = [usdt, usdc, dai];

    const updateTimestamps = [BigInt("1650886888"), BigInt("1650886630"), BigInt("1650886104")];
    const exponentialMovingAverages = [
        BigInt("31132626894697926"),
        BigInt("30109512549022512"),
        BigInt("32706669664256327"),
    ];
    const exponentialWeightedMovingVariances = [
        BigInt("1828129745656718"),
        BigInt("53273740801041"),
        BigInt("49811986068491"),
    ];

    const initialParams = {
        assets,
        updateTimestamps,
        exponentialMovingAverages,
        exponentialWeightedMovingVariances,
    };

    if (process.env.ITF_ENABLED === "true") {
        const ItfIporOracle = artifacts.require("ItfIporOracle");
        await itfScript(deployer, _network, addresses, ItfIporOracle, initialParams);
    } else {
        const IporOracle = artifacts.require("IporOracle");
        await script(deployer, _network, addresses, IporOracle, initialParams);
    }
};
