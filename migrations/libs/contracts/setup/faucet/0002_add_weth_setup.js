require("dotenv").config({ path: "../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const TestnetFaucet = artifacts.require("TestnetFaucet");

const MockTestnetTokenWeth= artifacts.require("MockTestnetTokenWeth");


module.exports = async function (deployer, _network, addresses) {
    const weth = await func.getValue(keys.WETH);

    const testnetFaucet = await func.getValue(keys.TestnetFaucetProxy);
    const testnetFaucetInstance = await TestnetFaucet.at(testnetFaucet);

    const wethInstance = await MockTestnetTokenWeth.at(weth);

    await wethInstance.transfer(testnetFaucet, process.env.SC_MIGRATION_FAUCET_INITIAL_STABLE_18_DECIMALS);
    await testnetFaucetInstance.addAsset(weth);
};
