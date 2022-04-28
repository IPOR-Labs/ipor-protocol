const keys = require("../json_keys.js");
const func = require("../json_func.js");

const MockTestnetTokenUsdt = artifacts.require("MockTestnetTokenUsdt");
const MockTestnetTokenUsdc = artifacts.require("MockTestnetTokenUsdc");
const MockTestnetTokenDai = artifacts.require("MockTestnetTokenDai");

const MockTestnetStrategyAaveUsdt = artifacts.require("MockTestnetStrategyAaveUsdt");
const MockTestnetStrategyAaveUsdc = artifacts.require("MockTestnetStrategyAaveUsdc");
const MockTestnetStrategyAaveDai = artifacts.require("MockTestnetStrategyAaveDai");

const MockTestnetStrategyCompoundUsdt = artifacts.require("MockTestnetStrategyCompoundUsdt");
const MockTestnetStrategyCompoundUsdc = artifacts.require("MockTestnetStrategyCompoundUsdc");
const MockTestnetStrategyCompoundDai = artifacts.require("MockTestnetStrategyCompoundDai");

module.exports = async function (deployer, _network, addresses) {
    const stanleyUsdt = await func.getValue(keys.StanleyProxyUsdt);
    const stanleyUsdc = await func.getValue(keys.StanleyProxyUsdc);
    const stanleyDai = await func.getValue(keys.StanleyProxyDai);

    const strategyAaveUsdt = await func.getValue(keys.AaveStrategyProxyUsdt);
    const strategyAaveUsdc = await func.getValue(keys.AaveStrategyProxyUsdc);
    const strategyAaveDai = await func.getValue(keys.AaveStrategyProxyDai);

    const strategyCompoundUsdt = await func.getValue(keys.CompoundStrategyProxyUsdt);
    const strategyCompoundUsdc = await func.getValue(keys.CompoundStrategyProxyUsdc);
    const strategyCompoundDai = await func.getValue(keys.CompoundStrategyProxyDai);

    const strategyAaveUsdtInstance = await MockTestnetStrategyAaveUsdt.at(strategyAaveUsdt);
    const strategyAaveUsdcInstance = await MockTestnetStrategyAaveUsdc.at(strategyAaveUsdc);
    const strategyAaveDaiInstance = await MockTestnetStrategyAaveDai.at(strategyAaveDai);

    await strategyAaveUsdtInstance.setStanley(stanleyUsdt);
    await strategyAaveUsdcInstance.setStanley(stanleyUsdc);
    await strategyAaveDaiInstance.setStanley(stanleyDai);

    const strategyCompoundUsdtInstance = await MockTestnetStrategyCompoundUsdt.at(
        strategyCompoundUsdt
    );
    const strategyCompoundUsdcInstance = await MockTestnetStrategyCompoundUsdc.at(
        strategyCompoundUsdc
    );
    const strategyCompoundDaiInstance = await MockTestnetStrategyCompoundDai.at(
        strategyCompoundDai
    );

    await strategyCompoundUsdtInstance.setStanley(stanleyUsdt);
    await strategyCompoundUsdcInstance.setStanley(stanleyUsdc);
    await strategyCompoundDaiInstance.setStanley(stanleyDai);

    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);

    const usdtInstance = await MockTestnetTokenUsdt.at(usdt);
    const usdcInstance = await MockTestnetTokenUsdc.at(usdc);
    const daiInstance = await MockTestnetTokenDai.at(dai);

    const initialValue6dec = BigInt("1000000000000");
    const initialValue18dec = BigInt("1000000000000000000000000");

    await usdtInstance.transfer(strategyAaveUsdt, initialValue6dec);
    await usdcInstance.transfer(strategyAaveUsdc, initialValue6dec);
    await daiInstance.transfer(strategyAaveDai, initialValue18dec);

    await usdtInstance.transfer(strategyCompoundUsdt, initialValue6dec);
    await usdcInstance.transfer(strategyCompoundUsdc, initialValue6dec);
    await daiInstance.transfer(strategyCompoundDai, initialValue18dec);
};
