// require("dotenv").config({ path: "../.env" });

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { deployProxyImpl } = require("@openzeppelin/truffle-upgrades/dist/utils");
const update = require("./json_update.js");
// const { artifacts } = require("hardhat");

// const keccak256 = require("keccak256");
const MiltonFaucet = artifacts.require("MiltonFaucet");
const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");

const MockAUsdc = artifacts.require("MockAUsdc");
const MockAUsdt = artifacts.require("MockAUsdt");
const MockADai = artifacts.require("MockADai");

const MockLendingPoolAave = artifacts.require("MockLendingPoolAave");
const MockProviderAave = artifacts.require("MockProviderAave");
const MockStakedAave = artifacts.require("MockStakedAave");
const AAVEMockedToken = artifacts.require("AAVEMockedToken");
const MockAaveIncentivesController = artifacts.require("MockAaveIncentivesController");
const MockWhitePaper = artifacts.require("MockWhitePaper");
const MockedCOMPTokenUSDT = artifacts.require("MockedCOMPTokenUSDT");
const MockedCOMPTokenUSDC = artifacts.require("MockedCOMPTokenUSDC");
const MockedCOMPTokenDAI = artifacts.require("MockedCOMPTokenDAI");
const MockComptrollerUSDT = artifacts.require("MockComptrollerUSDT");
const MockComptrollerUSDC = artifacts.require("MockComptrollerUSDC");
const MockComptrollerDAI = artifacts.require("MockComptrollerDAI");
const MockCDai = artifacts.require("MockCDai");
const MockCUSDT = artifacts.require("MockCUSDT");
const MockCUSDC = artifacts.require("MockCUSDC");

module.exports = async function (deployer, _network) {
    let stableTotalSupply6Decimals = "1000000000000000000";
    let stableTotalSupply18Decimals = "1000000000000000000000000000000";

    await deployer.deploy(UsdtMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdt = await UsdtMockedToken.deployed();

    await update("USDT", mockedUsdt.address);

    await deployer.deploy(UsdcMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdc = await UsdcMockedToken.deployed();

    await update("USDC", mockedUsdc.address);

    await deployer.deploy(DaiMockedToken, stableTotalSupply18Decimals, 18);
    const mockedDai = await DaiMockedToken.deployed();

    await update("DAI", mockedDai.address);

    await deployer.deploy(MockAUsdc);
    const mockedAUsdc = await MockAUsdc.deployed();

    await update("aUSDC", mockedAUsdc.address);

    await deployer.deploy(MockAUsdt);
    const mockedAUsdt = await MockAUsdt.deployed();

    await update("aUSDT", mockedAUsdt.address);

    await deployer.deploy(MockADai);
    const mockedADai = await MockADai.deployed();

    await update("aDAI", mockedADai.address);

    await deployer.deploy(AAVEMockedToken, stableTotalSupply18Decimals, 18);
    const mockedAAVE = await AAVEMockedToken.deployed();

    await update("AAVE", mockedAAVE.address);

    await deployer.deploy(
        MockLendingPoolAave,
        mockedDai.address,
        mockedADai.address,
        BigInt("1000000000000000000"),
        mockedUsdc.address,
        mockedAUsdc.address,
        BigInt("2000000"),
        mockedUsdt.address,
        mockedAUsdt.address,
        BigInt("2000000")
    );
    const mockedLendingPool = await MockLendingPoolAave.deployed();

    await deployer.deploy(MockProviderAave, mockedLendingPool.address);
    const mockedAaveProvider = await MockProviderAave.deployed();

    await update("AaveProvider", mockedAaveProvider.address);

    await deployer.deploy(MockStakedAave, mockedAAVE.address);
    const mockedStakedAave = await MockStakedAave.deployed();

    await update("AaveStaked", mockedStakedAave.address);

    await deployer.deploy(MockAaveIncentivesController, mockedStakedAave.address);
    const mockedAaveIncentivesController = await MockAaveIncentivesController.deployed();

    await update("AaveIncentivesController", mockedAaveIncentivesController.address);

    await deployer.deploy(MockWhitePaper);
    const mockedWhitePaperInstance = await MockWhitePaper.deployed();

    await deployer.deploy(MockCUSDC, mockedUsdc.address, mockedWhitePaperInstance.address);
    const mockedCUsdc = await MockCUSDC.deployed();

    await update("cUSDC", mockedCUsdc.address);

    await deployer.deploy(MockCUSDT, mockedUsdt.address, mockedWhitePaperInstance.address);
    const mockedCUsdt = await MockCUSDT.deployed();

    await update("cUSDT", mockedCUsdt.address);

    await deployer.deploy(MockCDai, mockedDai.address, mockedWhitePaperInstance.address);
    const mockedCDai = await MockCDai.deployed();

    await update("cDAI", mockedCDai.address);

    await deployer.deploy(MockedCOMPTokenDAI, stableTotalSupply18Decimals, 18);
    const mockedCOMPDAI = await MockedCOMPTokenDAI.deployed();

    await update("CompTokenForDai", mockedCOMPDAI.address);

    await deployer.deploy(MockedCOMPTokenUSDC, stableTotalSupply6Decimals, 6);
    const mockedCOMPUSDC = await MockedCOMPTokenUSDC.deployed();

    await update("CompTokenForUsdc", mockedCOMPUSDC.address);

    await deployer.deploy(MockedCOMPTokenUSDT, stableTotalSupply6Decimals, 6);
    const mockedCOMPUSDT = await MockedCOMPTokenUSDT.deployed();

    await update("CompTokenForUsdt", mockedCOMPUSDT.address);

    await deployer.deploy(MockComptrollerUSDT, mockedCOMPUSDT.address, mockedCUsdt.address);
    const mockedComptrollerUSDT = await MockComptrollerUSDT.deployed();

    await update("ComptrollerUsdt", mockedComptrollerUSDT.address);

    await deployer.deploy(MockComptrollerUSDC, mockedCOMPUSDC.address, mockedCUsdc.address);
    const mockedComptrollerUSDC = await MockComptrollerUSDC.deployed();

    await update("ComptrollerUsdc", mockedComptrollerUSDC.address);

    await deployer.deploy(MockComptrollerDAI, mockedCOMPDAI.address, mockedCDai.address);
    const mockedComptrollerDAI = await MockComptrollerDAI.deployed();

    await update("ComptrollerDai", mockedComptrollerDAI.address);

    //TODO: use TestnetFaucet
    await deployer.deploy(MiltonFaucet);
    const faucet = await MiltonFaucet.deployed();

    await update("IporFaucet", faucet.address);
};
