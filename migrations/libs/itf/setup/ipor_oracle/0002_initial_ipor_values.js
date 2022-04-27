const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const ItfIporOracle = artifacts.require("ItfIporOracle");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);

    const iporOracle = await func.getValue(keys.ItfIporOracleProxy);

    const iporOracleInstance = await ItfIporOracle.at(iporOracle);

    await iporOracleInstance.updateIndexes(
        [usdt, usdc, dai],
        [BigInt("30000000000000000"), BigInt("30000000000000000"), BigInt("30000000000000000")]
    );
};
