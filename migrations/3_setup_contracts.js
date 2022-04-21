require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { erc1967, deployProxy } = require("@openzeppelin/truffle-upgrades");

const TestnetFaucet = artifacts.require("TestnetFaucet");

const IvTokenUsdt = artifacts.require("IvTokenUsdt");
const IvTokenUsdc = artifacts.require("IvTokenUsdc");
const IvTokenDai = artifacts.require("IvTokenDai");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");



const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");

const ItfStanleyUsdt = artifacts.require("ItfStanleyUsdt");
const ItfStanleyUsdc = artifacts.require("ItfStanleyUsdc");
const ItfStanleyDai = artifacts.require("ItfStanleyDai");

const IporOracle = artifacts.require("IporOracle");

const JosephUsdt = artifacts.require("JosephUsdt");
const JosephUsdc = artifacts.require("JosephUsdc");
const JosephDai = artifacts.require("JosephDai");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

const ItfIporOracle = artifacts.require("ItfIporOracle");

const ItfJosephUsdt = artifacts.require("ItfJosephUsdt");
const ItfJosephUsdc = artifacts.require("ItfJosephUsdc");
const ItfJosephDai = artifacts.require("ItfJosephDai");

const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");
const ItfMiltonDai = artifacts.require("ItfMiltonDai");

module.exports = async function (deployer, _network, addresses) {
    console.log("Setup Smart contracts...");
    const [admin, iporIndexAdmin, userTwo, userThree, _] = addresses;

    console.log("admin wallet: ", admin);
    console.log("iporIndexAdmin wallet: ", iporIndexAdmin);    

    if (process.env.ITF_ENABLED === "true") {
        console.log("Setup contracts for Ipor Test Framework...");
        await itfMiltonUsdtProxy.setJoseph(itfJosephUsdtProxy.address);
        await itfMiltonUsdcProxy.setJoseph(itfJosephUsdcProxy.address);
        await itfMiltonDaiProxy.setJoseph(itfJosephDaiProxy.address);

        await itfMiltonUsdtProxy.setupMaxAllowanceForAsset(itfJosephUsdtProxy.address);
        await itfMiltonUsdcProxy.setupMaxAllowanceForAsset(itfJosephUsdcProxy.address);
        await itfMiltonDaiProxy.setupMaxAllowanceForAsset(itfJosephDaiProxy.address);

        await itfMiltonUsdtProxy.setupMaxAllowanceForAsset(itfStanleyUsdtProxy.address);
        await itfMiltonUsdcProxy.setupMaxAllowanceForAsset(itfStanleyUsdcProxy.address);
        await itfMiltonDaiProxy.setupMaxAllowanceForAsset(itfStanleyDaiProxy.address);

        const itfIporOracleProxy = await ItfIporOracle.deployed();

        await itfIporOracleProxy.addUpdater(admin);
        await itfIporOracleProxy.addUpdater(iporIndexAdmin);
        await itfIporOracleProxy.addAsset(mockedUsdt.address);
        await itfIporOracleProxy.addAsset(mockedUsdc.address);
        await itfIporOracleProxy.addAsset(mockedDai.address);

        await ipUsdtToken.setJoseph(itfJosephUsdtProxy.address);
        await ipUsdcToken.setJoseph(itfJosephUsdcProxy.address);
        await ipDaiToken.setJoseph(itfJosephDaiProxy.address);

        await miltonStorageUsdtProxy.setJoseph(itfJosephUsdtProxy.address);
        await miltonStorageUsdcProxy.setJoseph(itfJosephUsdcProxy.address);
        await miltonStorageDaiProxy.setJoseph(itfJosephDaiProxy.address);

        await miltonStorageUsdtProxy.setMilton(itfMiltonUsdtProxy.address);
        await miltonStorageUsdcProxy.setMilton(itfMiltonUsdcProxy.address);
        await miltonStorageDaiProxy.setMilton(itfMiltonDaiProxy.address);

        await itfStanleyUsdtProxy.setMilton(itfMiltonUsdtProxy.address);
        await itfStanleyUsdcProxy.setMilton(itfMiltonUsdcProxy.address);
        await itfStanleyDaiProxy.setMilton(itfMiltonDaiProxy.address);

        await ivUsdtToken.setStanley(itfStanleyUsdtProxy.address);
        await ivUsdcToken.setStanley(itfStanleyUsdcProxy.address);
        await ivDaiToken.setStanley(itfStanleyDaiProxy.address);

        await strategyAaveUsdtProxy.setStanley(itfStanleyUsdtProxy.address);
        await strategyAaveUsdcProxy.setStanley(itfStanleyUsdcProxy.address);
        await strategyAaveDaiProxy.setStanley(itfStanleyDaiProxy.address);

        await strategyCompoundUsdtProxy.setStanley(itfStanleyUsdtProxy.address);
        await strategyCompoundUsdcProxy.setStanley(itfStanleyUsdcProxy.address);
        await strategyCompoundDaiProxy.setStanley(itfStanleyDaiProxy.address);

        if (process.env.INITIAL_IPOR_MIGRATION_ENABLED === "true") {
            console.log("Setup initial IPOR values...");
            await itfIporOracleProxy.updateIndexes(
                [mockedDai.address, mockedUsdt.address, mockedUsdc.address],
                [
                    BigInt("30000000000000000"),
                    BigInt("30000000000000000"),
                    BigInt("30000000000000000"),
                ]
            );
            console.log("Setup initial IPOR values finished.");
        }
    } else {

        if (process.env.INITIAL_IPOR_MIGRATION_ENABLED === "true") {
            console.log("Setup initial IPOR values...");
            await iporOracleProxy.updateIndexes(
                [mockedDai.address, mockedUsdt.address, mockedUsdc.address],
                [
                    BigInt("30000000000000000"),
                    BigInt("30000000000000000"),
                    BigInt("30000000000000000"),
                ]
            );
            console.log("Setup initial IPOR values finished.");
        }
    }

    console.log("Setup Faucet...");
    const testnetFaucet = await TestnetFaucet.deployed();
    testnetFaucet.sendTransaction({
        from: admin,
        value: "500000000000000000000000",
    });
    await mockedUsdt.transfer(testnetFaucet.address, faucetSupply6Decimals);
    await mockedUsdc.transfer(testnetFaucet.address, faucetSupply6Decimals);
    await mockedDai.transfer(testnetFaucet.address, faucetSupply18Decimals);
    console.log("Setup Faucet finished.");

    console.log("Congratulations! Setup Smart Contracts finished!");
};
