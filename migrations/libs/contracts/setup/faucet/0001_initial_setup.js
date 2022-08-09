require("dotenv").config({ path: "../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const TestnetFaucet = artifacts.require("TestnetFaucet");

const MockTestnetTokenUsdt = artifacts.require("MockTestnetTokenUsdt");
const MockTestnetTokenUsdc = artifacts.require("MockTestnetTokenUsdc");
const MockTestnetTokenDai = artifacts.require("MockTestnetTokenDai");

module.exports = async function (deployer, _network, addresses) {
    const [admin, _] = addresses;

    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);

    const testnetFaucet = await func.getValue(keys.TestnetFaucetProxy);

    const testnetFaucetInstance = await TestnetFaucet.at(testnetFaucet);

    const usdtInstance = await MockTestnetTokenUsdt.at(usdt);
    const usdcInstance = await MockTestnetTokenUsdc.at(usdc);
    const daiInstance = await MockTestnetTokenDai.at(dai);

    await testnetFaucetInstance.sendTransaction({
        from: admin,
        value: process.env.SC_MIGRATION_FAUCET_INITIAL_ETH,
    });

    await usdtInstance.transfer(testnetFaucet, process.env.SC_MIGRATION_FAUCET_INITIAL_STABLE_6_DECIMALS);
    await usdcInstance.transfer(testnetFaucet, process.env.SC_MIGRATION_FAUCET_INITIAL_STABLE_6_DECIMALS);
    await daiInstance.transfer(testnetFaucet, process.env.SC_MIGRATION_FAUCET_INITIAL_STABLE_18_DECIMALS);
};
