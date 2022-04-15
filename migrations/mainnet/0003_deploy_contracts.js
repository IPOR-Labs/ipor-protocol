// require("dotenv").config({ path: "../.env" });

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const { deployProxyImpl } = require("@openzeppelin/truffle-upgrades/dist/utils");
// const { artifacts } = require("hardhat");

// const keccak256 = require("keccak256");
const MiltonFaucet = artifacts.require("MiltonFaucet");
const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");
const IpTokenUsdt = artifacts.require("IpTokenUsdt");
const IpTokenUsdc = artifacts.require("IpTokenUsdc");
const IpTokenDai = artifacts.require("IpTokenDai");

const MockAUsdc = artifacts.require("MockAUsdc");
const MockAUsdt = artifacts.require("MockAUsdt");
const MockADai = artifacts.require("MockADai");

const IvTokenUsdt = artifacts.require("IvTokenUsdt");
const IvTokenUsdc = artifacts.require("IvTokenUsdc");
const IvTokenDai = artifacts.require("IvTokenDai");
const StrategyAaveUsdt = artifacts.require("StrategyAaveUsdt");
const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");
const StrategyAaveDai = artifacts.require("StrategyAaveDai");
const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");
const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");
const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");
const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");
const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");
const IporOracle = artifacts.require("IporOracle");
const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");
const JosephUsdt = artifacts.require("JosephUsdt");
const JosephUsdc = artifacts.require("JosephUsdc");
const JosephDai = artifacts.require("JosephDai");
const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");
const CockpitDataProvider = artifacts.require("CockpitDataProvider");
const MiltonFacadeDataProvider = artifacts.require("MiltonFacadeDataProvider");
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

    await deployer.deploy(UsdcMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdc = await UsdcMockedToken.deployed();

    await deployer.deploy(DaiMockedToken, stableTotalSupply18Decimals, 18);
    const mockedDai = await DaiMockedToken.deployed();

    await deployer.deploy(MockAUsdc);
    const mockedAUsdc = await MockAUsdc.deployed();

    await deployer.deploy(MockAUsdt);
    const mockedAUsdt = await MockAUsdt.deployed();

    await deployer.deploy(MockADai);
    const mockedADai = await MockADai.deployed();

    await deployer.deploy(AAVEMockedToken, stableTotalSupply18Decimals, 18);
    const mockedAAVE = await AAVEMockedToken.deployed();

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

    await deployer.deploy(MockStakedAave, mockedAAVE.address);
    const mockedStakedAave = await MockStakedAave.deployed();

    await deployer.deploy(MockAaveIncentivesController, mockedStakedAave.address);
    const mockedAaveIncentivesController = await MockAaveIncentivesController.deployed();

    await deployer.deploy(MockWhitePaper);
    const mockedWhitePaperInstance = await MockWhitePaper.deployed();

    await deployer.deploy(MockCUSDC, mockedUsdc.address, mockedWhitePaperInstance.address);
    const mockedCUsdc = await MockCUSDC.deployed();

    await deployer.deploy(MockCUSDT, mockedUsdt.address, mockedWhitePaperInstance.address);
    const mockedCUsdt = await MockCUSDT.deployed();

    await deployer.deploy(MockCDai, mockedDai.address, mockedWhitePaperInstance.address);
    const mockedCDai = await MockCDai.deployed();

    await deployer.deploy(MockedCOMPTokenDAI, stableTotalSupply18Decimals, 18);
    const mockedCOMPDAI = await MockedCOMPTokenDAI.deployed();

    await deployer.deploy(MockedCOMPTokenUSDC, stableTotalSupply6Decimals, 6);
    const mockedCOMPUSDC = await MockedCOMPTokenUSDC.deployed();

    await deployer.deploy(MockedCOMPTokenUSDT, stableTotalSupply6Decimals, 6);
    const mockedCOMPUSDT = await MockedCOMPTokenUSDT.deployed();

    await deployer.deploy(MockComptrollerUSDT, mockedCOMPUSDT.address, mockedCUsdt.address);
    const mockComptrollerUSDT = await MockComptrollerUSDT.deployed();

    await deployer.deploy(MockComptrollerUSDC, mockedCOMPUSDC.address, mockedCUsdc.address);
    const mockComptrollerUSDC = await MockComptrollerUSDC.deployed();

    await deployer.deploy(MockComptrollerDAI, mockedCOMPDAI.address, mockedCDai.address);
    const mockComptrollerDAI = await MockComptrollerDAI.deployed();

    await deployer.deploy(MiltonFaucet);
    const miltonFaucet = await MiltonFaucet.deployed();
	
	//------------------------------------
    

    await deployer.deploy(IpTokenUsdt, "IP USDT", "ipUSDT", mockedUsdt.address);
    const ipTokenUsdt = await IpTokenUsdt.deployed();

    await deployer.deploy(IpTokenUsdc, "IP USDC", "ipUSDC", mockedUsdc.address);
    const ipTokenUsdc = await IpTokenUsdc.deployed();

    await deployer.deploy(IpTokenDai, "IP DAI", "ipDAI", mockedDai.address);
    const ipTokenDai = await IpTokenDai.deployed();

    await deployer.deploy(IvTokenUsdt, "IV USDT", "ivUSDT", mockedUsdt.address);
    const ivTokenUsdt = await IvTokenUsdt.deployed();

    await deployer.deploy(IvTokenUsdc, "IV USDC", "ivUSDC", mockedUsdc.address);
    const ivTokenUsdc = await IvTokenUsdc.deployed();

    await deployer.deploy(IvTokenDai, "IV DAI", "ivDAI", mockedDai.address);
    const ivTokenDai = await IvTokenDai.deployed();

    const strategyAaveUsdt = await deployProxy(
        StrategyAaveUsdt,
        [
            mockedUsdt.address,
            mockedAUsdt.address,
            aaveProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const strategyAaveUsdc = await deployProxy(
        StrategyAaveUsdc,
        [
            mockedUsdc.address,
            mockedAUsdc.address,
            aaveProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const strategyAaveDai = await deployProxy(
        StrategyAaveDai,
        [
            mockedDai.address,
            mockedADai.address,
            aaveProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    await deployer.deploy(MiltonSpreadModel);
    const miltonSpreadModel = await MiltonSpreadModel.deployed();

    const strategyCompoundUsdt = await deployProxy(
        StrategyCompoundUsdt,
        [
            mockedUsdt.address,
            mockedCUsdt.address,
            mockComptrollerUSDT.address,
            mockedCOMPUSDT.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const strategyCompoundUsdc = await deployProxy(
        StrategyCompoundUsdc,
        [
            mockedUsdc.address,
            mockedCUsdc.address,
            mockComptrollerUSDC.address,
            mockedCOMPUSDC.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const strategyCompoundDai = await deployProxy(
        StrategyCompoundDai,
        [mockedDai.address, mockedCDai.address, mockComptrollerDAI.address, mockedCOMPDAI.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyUsdt = await deployProxy(
        StanleyUsdt,
        [
            mockedUsdt.address,
            ivTokenUsdt.address,
            strategyAaveUsdt.address,
            strategyCompoundUsdt.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyUsdc = await deployProxy(
        StanleyUsdc,
        [
            mockedUsdc.address,
            ivTokenUsdc.address,
            strategyAaveUsdc.address,
            strategyCompoundUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyDai = await deployProxy(
        StanleyDai,
        [
            mockedDai.address,
            ivTokenDai.address,
            strategyAaveDai.address,
            strategyCompoundDai.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonStorageUsdt = await deployProxy(MiltonStorageUsdt, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageUsdc = await deployProxy(MiltonStorageUsdc, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageDai = await deployProxy(MiltonStorageDai, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const iporOracle = await deployProxy(IporOracle, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonUsdt = await deployProxy(
        MiltonUsdt,
        [
            mockedUsdt.address,
            iporOracle.address,
            miltonStorageUsdt.address,
            miltonSpreadModel.address,
            stanleyUsdt.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonUsdc = await deployProxy(
        MiltonUsdc,
        [
            mockedUsdc.address,
            iporOracle.address,
            miltonStorageUsdc.address,
            miltonSpreadModel.address,
            stanleyUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonDai = await deployProxy(
        MiltonDai,
        [
            mockedDai.address,
            iporOracle.address,
            miltonStorageDai.address,
            miltonSpreadModel.address,
            stanleyDai.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephUsdt = await deployProxy(
        JosephUsdt,
        [
            mockedUsdt.address,
            ipTokenUsdt.address,
            miltonUsdt.address,
            miltonStorageUsdt.address,
            stanleyUsdt.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephUsdc = await deployProxy(
        JosephUsdc,
        [
            mockedUsdc.address,
            ipTokenUsdc.address,
            miltonUsdc.address,
            miltonStorageUsdc.address,
            stanleyUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephDai = await deployProxy(
        JosephDai,
        [
            mockedDai.address,
            ipTokenDai.address,
            miltonDai.address,
            miltonStorageDai.address,
            stanleyDai.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const iporOracleDarcyDataProvider = await deployProxy(
        IporOracleFacadeDataProvider,
        [[mockedDai.address, mockedUsdt.address, mockedUsdc.address], iporOracle.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonDevToolDataProvider = await deployProxy(
        CockpitDataProvider,
        [
            iporOracle.address,
            [mockedUsdt.address, mockedUsdc.address, mockedDai.address],
            [miltonUsdt.address, miltonUsdc.address, miltonDai.address],
            [miltonStorageUsdt.address, miltonStorageUsdc.address, miltonStorageDai.address],
            [josephUsdt.address, josephUsdc.address, josephDai.address],
            [ipTokenUsdt.address, ipTokenUsdc.address, ipTokenDai.address],
            [ivTokenUsdt.address, ivTokenUsdc.address, ivTokenDai.address],
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );
    const miltonFacadeDataProvider = await deployProxy(
        MiltonFacadeDataProvider,
        [
            iporOracle.address,
            [mockedUsdt.address, mockedUsdc.address, mockedDai.address],
            [miltonUsdt.address, miltonUsdc.address, miltonDai.address],
            [miltonStorageUsdt.address, miltonStorageUsdc.address, miltonStorageDai.address],
            [josephUsdt.address, josephUsdc.address, josephDai.address],
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    console.log("Congratulations! DEPLOY Smart Contracts finished!");
};
