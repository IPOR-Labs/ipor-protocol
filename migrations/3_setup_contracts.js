require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { erc1967, deployProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonFaucet = artifacts.require("MiltonFaucet");

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");

const IpTokenUsdt = artifacts.require("IpTokenUsdt");
const IpTokenUsdc = artifacts.require("IpTokenUsdc");
const IpTokenDai = artifacts.require("IpTokenDai");

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

const Warren = artifacts.require("Warren");

const JosephUsdt = artifacts.require("JosephUsdt");
const JosephUsdc = artifacts.require("JosephUsdc");
const JosephDai = artifacts.require("JosephDai");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

const ItfWarren = artifacts.require("ItfWarren");

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

        await itfMiltonUsdtProxy.setupMaxAllowance(itfJosephUsdtProxy.address);
        await itfMiltonUsdcProxy.setupMaxAllowance(itfJosephUsdcProxy.address);
        await itfMiltonDaiProxy.setupMaxAllowance(itfJosephDaiProxy.address);

        const itfWarrenProxy = await ItfWarren.deployed();

        await itfWarrenProxy.addUpdater(admin);
        await itfWarrenProxy.addUpdater(iporIndexAdmin);
        await itfWarrenProxy.addAsset(mockedUsdt.address);
        await itfWarrenProxy.addAsset(mockedUsdc.address);
        await itfWarrenProxy.addAsset(mockedDai.address);

        await ipUsdtToken.setJoseph(itfJosephUsdtProxy.address);
        await ipUsdcToken.setJoseph(itfJosephUsdcProxy.address);
        await ipDaiToken.setJoseph(itfJosephDaiProxy.address);

        await miltonStorageUsdtProxy.setJoseph(itfJosephUsdtProxy.address);
        await miltonStorageUsdcProxy.setJoseph(itfJosephUsdcProxy.address);
        await miltonStorageDaiProxy.setJoseph(itfJosephDaiProxy.address);

        await miltonStorageUsdtProxy.setMilton(itfMiltonUsdtProxy.address);
        await miltonStorageUsdcProxy.setMilton(itfMiltonUsdcProxy.address);
        await miltonStorageDaiProxy.setMilton(itfMiltonDaiProxy.address);

        await stanleyUsdtProxy.setMilton(itfMiltonUsdtProxy.address);
        await stanleyUsdcProxy.setMilton(itfMiltonUsdcProxy.address);
        await stanleyDaiProxy.setMilton(itfMiltonDaiProxy.address);

        await strategyAaveUsdtProxy.setStanley(stanleyUsdtProxy.address);
        await strategyAaveUsdcProxy.setStanley(stanleyUsdcProxy.address);
        await strategyAaveDaiProxy.setStanley(stanleyDaiProxy.address);

        await strategyCompoundUsdtProxy.setStanley(stanleyUsdtProxy.address);
        await strategyCompoundUsdcProxy.setStanley(stanleyUsdcProxy.address);
        await strategyCompoundDaiProxy.setStanley(stanleyDaiProxy.address);

        if (process.env.INITIAL_IPOR_MIGRATION_ENABLED === "true") {
            console.log("Setup initial IPOR values...");
            await itfWarrenProxy.updateIndexes(
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

        await miltonUsdtProxy.setupMaxAllowance(josephUsdtProxy.address);
        await miltonUsdcProxy.setupMaxAllowance(josephUsdcProxy.address);
        await miltonDaiProxy.setupMaxAllowance(josephDaiProxy.address);

        const warrenProxy = await Warren.deployed();
        await warrenProxy.addUpdater(admin);
        await warrenProxy.addUpdater(iporIndexAdmin);
        await warrenProxy.addAsset(mockedUsdt.address);
        await warrenProxy.addAsset(mockedUsdc.address);
        await warrenProxy.addAsset(mockedDai.address);

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

        await strategyAaveUsdtProxy.setStanley(stanleyUsdtProxy.address);
        await strategyAaveUsdcProxy.setStanley(stanleyUsdcProxy.address);
        await strategyAaveDaiProxy.setStanley(stanleyDaiProxy.address);

        await strategyCompoundUsdtProxy.setStanley(stanleyUsdtProxy.address);
        await strategyCompoundUsdcProxy.setStanley(stanleyUsdcProxy.address);
        await strategyCompoundDaiProxy.setStanley(stanleyDaiProxy.address);

        if (process.env.INITIAL_IPOR_MIGRATION_ENABLED === "true") {
            console.log("Setup initial IPOR values...");
            await warrenProxy.updateIndexes(
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
