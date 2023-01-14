require("dotenv").config({ path: "../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MockTestnetTokenUsdt = artifacts.require("MockTestnetTokenUsdt");
const MockTestnetTokenUsdc = artifacts.require("MockTestnetTokenUsdc");
const MockTestnetTokenDai = artifacts.require("MockTestnetTokenDai");
const IporToken = artifacts.require("IporToken");

module.exports = async function (deployer, _network, addresses, TestnetFaucet) {
    const [admin, _] = addresses;

    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);
    const iporToken = await func.getValue(keys.IPOR);

    const testnetFaucet = await deployProxy(TestnetFaucet, [dai, usdc, usdt, iporToken], {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });
    const testnetFaucetImpl = await erc1967.getImplementationAddress(testnetFaucet.address);
    await func.update(keys.TestnetFaucetProxy, testnetFaucet.address);
    await func.update(keys.TestnetFaucetImpl, testnetFaucetImpl);

    const usdtInstance = await MockTestnetTokenUsdt.at(usdt);
    const usdcInstance = await MockTestnetTokenUsdc.at(usdc);
    const daiInstance = await MockTestnetTokenDai.at(dai);
    const iporTokenInstance = await IporToken.at(iporToken);

    await testnetFaucet.sendTransaction({
        from: admin,
        value: process.env.SC_MIGRATION_FAUCET_INITIAL_ETH,
    });

    await usdtInstance.transfer(
        testnetFaucet.address,
        process.env.SC_MIGRATION_FAUCET_INITIAL_STABLE_6_DECIMALS
    );
    await usdcInstance.transfer(
        testnetFaucet.address,
        process.env.SC_MIGRATION_FAUCET_INITIAL_STABLE_6_DECIMALS
    );
    await daiInstance.transfer(
        testnetFaucet.address,
        process.env.SC_MIGRATION_FAUCET_INITIAL_STABLE_18_DECIMALS
    );
    await iporTokenInstance.transfer(
        testnetFaucet.address,
        process.env.SC_MIGRATION_FAUCET_INITIAL_IPOR_TOKEN
    );
};
