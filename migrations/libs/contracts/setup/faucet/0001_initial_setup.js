require("dotenv").config({ path: "../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const TestnetFaucet = artifacts.require("TestnetFaucet");

const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const usdt = await func.get_value(keys.USDT);
    const usdc = await func.get_value(keys.USDC);
    const dai = await func.get_value(keys.DAI);

    const testnetFaucet = await func.get_value(keys.TestnetFaucetProxy);

    const testnetFaucetInstance = await TestnetFaucet.at(testnetFaucet);

    const usdtInstance = await UsdtMockedToken.at(usdt);
    const usdcInstance = await UsdcMockedToken.at(usdc);
    const daiInstance = await DaiMockedToken.at(dai);

    await testnetFaucetInstance.sendTransaction({
        from: admin,
        value: process.env.FAUCET_INITIAL_ETH,
    });

    await usdtInstance.transfer(testnetFaucet, process.env.FAUCET_INITIAL_STABLE_6_DECIMALS);
    await usdcInstance.transfer(testnetFaucet, process.env.FAUCET_INITIAL_STABLE_6_DECIMALS);
    await daiInstance.transfer(testnetFaucet, process.env.FAUCET_INITIAL_STABLE_18_DECIMALS);
};
