const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");
const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");
const StrategyAaveDai = artifacts.require("StrategyAaveDai");
const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");
const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");
const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");

module.exports = async function (deployer, _network, addresses) {
    const rinkebyIporProtocolOwner = "0xa8Ff215b1127f052ad4403737FEaAb40a29740c0";

    const strategyCompoundUsdt = await func.getValue(keys.CompoundStrategyProxyUsdt);
    const strategyCompoundUsdc = await func.getValue(keys.CompoundStrategyProxyUsdc);
    const strategyCompoundDai = await func.getValue(keys.CompoundStrategyProxyDai);

    const strategyCompoundUsdtInstance = await StrategyCompoundUsdt.at(strategyCompoundUsdt);
    const strategyCompoundUsdcInstance = await StrategyCompoundUsdc.at(strategyCompoundUsdc);
    const strategyCompoundDaiInstance = await StrategyCompoundDai.at(strategyCompoundDai);

    await strategyCompoundUsdtInstance.transferOwnership(rinkebyIporProtocolOwner);
    await strategyCompoundUsdcInstance.transferOwnership(rinkebyIporProtocolOwner);
    await strategyCompoundDaiInstance.transferOwnership(rinkebyIporProtocolOwner);
};
