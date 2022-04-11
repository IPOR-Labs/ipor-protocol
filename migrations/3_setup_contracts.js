require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { erc1967, deployProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonFaucet = artifacts.require("MiltonFaucet");

const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");

const IpTokenUsdt = artifacts.require("IpTokenUsdt");
const IpTokenUsdc = artifacts.require("IpTokenUsdc");
const IpTokenDai = artifacts.require("IpTokenDai");
const IvTokenUsdt = artifacts.require("IvTokenUsdt");
const IvTokenUsdc = artifacts.require("IvTokenUsdc");
const IvTokenDai = artifacts.require("IvTokenDai");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");
const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");
const StrategyAaveDai = artifacts.require("StrategyAaveDai");
const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");
const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");
const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");

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

    const faucetSupply6Decimals = "10000000000000000";
    const faucetSupply18Decimals = "10000000000000000000000000000";

    //#####################################################################
    // CONFIG STABLE - BEGIN
    //#####################################################################
    console.log("Setup stable coins....");

    const mockedUsdt = await UsdtMockedToken.deployed();
    const mockedUsdc = await UsdcMockedToken.deployed();
    const mockedDai = await DaiMockedToken.deployed();

    const miltonStorageUsdtProxy = await MiltonStorageUsdt.deployed();
    const miltonStorageUsdcProxy = await MiltonStorageUsdc.deployed();
    const miltonStorageDaiProxy = await MiltonStorageDai.deployed();

    //#####################################################################
    // CONFIG STABLE - END
    //#####################################################################

    const ipUsdtToken = await IpTokenUsdt.deployed();
    const ipUsdcToken = await IpTokenUsdc.deployed();
    const ipDaiToken = await IpTokenDai.deployed();

    const ivUsdtToken = await IvTokenUsdt.deployed();
    const ivUsdcToken = await IvTokenUsdc.deployed();
    const ivDaiToken = await IvTokenDai.deployed();

    const josephUsdtProxy = await JosephUsdt.deployed();
    const josephUsdcProxy = await JosephUsdc.deployed();
    const josephDaiProxy = await JosephDai.deployed();

    const itfJosephUsdtProxy = await ItfJosephUsdt.deployed();
    const itfJosephUsdcProxy = await ItfJosephUsdc.deployed();
    const itfJosephDaiProxy = await ItfJosephDai.deployed();

    const miltonUsdtProxy = await MiltonUsdt.deployed();
    const miltonUsdcProxy = await MiltonUsdc.deployed();
    const miltonDaiProxy = await MiltonDai.deployed();

    const itfMiltonUsdtProxy = await ItfMiltonUsdt.deployed();
    const itfMiltonUsdcProxy = await ItfMiltonUsdc.deployed();
    const itfMiltonDaiProxy = await ItfMiltonDai.deployed();

    const stanleyUsdtProxy = await StanleyUsdt.deployed();
    const stanleyUsdcProxy = await StanleyUsdc.deployed();
    const stanleyDaiProxy = await StanleyDai.deployed();

    const itfStanleyUsdtProxy = await ItfStanleyUsdt.deployed();
    const itfStanleyUsdcProxy = await ItfStanleyUsdc.deployed();
    const itfStanleyDaiProxy = await ItfStanleyDai.deployed();

    const strategyAaveUsdtProxy = await StrategyAaveUsdt.deployed();
    const strategyAaveUsdcProxy = await StrategyAaveUsdc.deployed();
    const strategyAaveDaiProxy = await StrategyAaveDai.deployed();

    const strategyCompoundUsdtProxy = await StrategyCompoundUsdt.deployed();
    const strategyCompoundUsdcProxy = await StrategyCompoundUsdc.deployed();
    const strategyCompoundDaiProxy = await StrategyCompoundDai.deployed();

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
        console.log("Setup contracts...");

        await miltonUsdtProxy.setJoseph(josephUsdtProxy.address);
        await miltonUsdcProxy.setJoseph(josephUsdcProxy.address);
        await miltonDaiProxy.setJoseph(josephDaiProxy.address);

        await miltonUsdtProxy.setupMaxAllowanceForAsset(josephUsdtProxy.address);
        await miltonUsdcProxy.setupMaxAllowanceForAsset(josephUsdcProxy.address);
        await miltonDaiProxy.setupMaxAllowanceForAsset(josephDaiProxy.address);

        await miltonUsdtProxy.setupMaxAllowanceForAsset(stanleyUsdtProxy.address);
        await miltonUsdcProxy.setupMaxAllowanceForAsset(stanleyUsdcProxy.address);
        await miltonDaiProxy.setupMaxAllowanceForAsset(stanleyDaiProxy.address);

        const iporOracleProxy = await IporOracle.deployed();
        await iporOracleProxy.addUpdater(admin);
        await iporOracleProxy.addUpdater(iporIndexAdmin);
        await iporOracleProxy.addAsset(mockedUsdt.address);
        await iporOracleProxy.addAsset(mockedUsdc.address);
        await iporOracleProxy.addAsset(mockedDai.address);

        await ipUsdtToken.setJoseph(josephUsdtProxy.address);
        await ipUsdcToken.setJoseph(josephUsdcProxy.address);
        await ipDaiToken.setJoseph(josephDaiProxy.address);

        await miltonStorageUsdtProxy.setJoseph(josephUsdtProxy.address);
        await miltonStorageUsdcProxy.setJoseph(josephUsdcProxy.address);
        await miltonStorageDaiProxy.setJoseph(josephDaiProxy.address);

        await miltonStorageUsdtProxy.setMilton(miltonUsdtProxy.address);
        await miltonStorageUsdcProxy.setMilton(miltonUsdcProxy.address);
        await miltonStorageDaiProxy.setMilton(miltonDaiProxy.address);

        await stanleyUsdtProxy.setMilton(miltonUsdtProxy.address);
        await stanleyUsdcProxy.setMilton(miltonUsdcProxy.address);
        await stanleyDaiProxy.setMilton(miltonDaiProxy.address);

        await ivUsdtToken.setStanley(stanleyUsdtProxy.address);
        await ivUsdcToken.setStanley(stanleyUsdcProxy.address);
        await ivDaiToken.setStanley(stanleyDaiProxy.address);

        await strategyAaveUsdtProxy.setStanley(stanleyUsdtProxy.address);
        await strategyAaveUsdcProxy.setStanley(stanleyUsdcProxy.address);
        await strategyAaveDaiProxy.setStanley(stanleyDaiProxy.address);

        await strategyCompoundUsdtProxy.setStanley(stanleyUsdtProxy.address);
        await strategyCompoundUsdcProxy.setStanley(stanleyUsdcProxy.address);
        await strategyCompoundDaiProxy.setStanley(stanleyDaiProxy.address);

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
    const miltonFaucet = await MiltonFaucet.deployed();
    miltonFaucet.sendTransaction({
        from: admin,
        value: "500000000000000000000000",
    });
    await mockedUsdt.transfer(miltonFaucet.address, faucetSupply6Decimals);
    await mockedUsdc.transfer(miltonFaucet.address, faucetSupply6Decimals);
    await mockedDai.transfer(miltonFaucet.address, faucetSupply18Decimals);
    console.log("Setup Faucet finished.");

    console.log("Congratulations! Setup Smart Contracts finished!");
};
