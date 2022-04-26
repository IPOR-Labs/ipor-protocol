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
        BigInt("3113262689469792600"),
        BigInt("3010951254902251200"),
        BigInt("3270666966425632700"),
    ];
    const exponentialWeightedMovingVariances = [
        BigInt("182812974565671780"),
        BigInt("5327374080104115"),
        BigInt("4981198606849136"),
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
	await func.updateLastCompletedMigration();
};
