const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const IporOracle = artifacts.require("IporOracle");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const usdt = await func.get_value(keys.USDT);
    const usdc = await func.get_value(keys.USDC);
    const dai = await func.get_value(keys.DAI);

    const iporOracle = await func.get_value(keys.IporOracleProxy);

    const iporOracleInstance = await IporOracle.at(iporOracle);

    await iporOracleInstance.addUpdater(admin);
    await iporOracleInstance.addUpdater(iporIndexAdmin);

    await iporOracleInstance.addAsset(usdt);
    await iporOracleInstance.addAsset(usdc);
    await iporOracleInstance.addAsset(dai);
};
