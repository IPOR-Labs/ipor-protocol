require("dotenv").config({ path: "../../../.env" });
const keys = require("../../libs/json_keys.js");
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/ipor_oracle/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);

    const assets = [usdt, usdc, dai];

    //TODO: Setup apropriate params before deploy on mainnet
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

    const IporOracle = artifacts.require("IporOracle");
    await script(deployer, _network, addresses, IporOracle, initialParams);

    await func.updateLastCompletedMigration();
};
