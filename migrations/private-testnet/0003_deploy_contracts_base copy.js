// require("dotenv").config({ path: "../.env" });

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");
const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");
const StrategyCompoundDai = artifacts.require("StrategyCompoundDai");
const StanleyUsdt = artifacts.require("StanleyUsdt");
const StanleyUsdc = artifacts.require("StanleyUsdc");
const StanleyDai = artifacts.require("StanleyDai");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");
const JosephUsdt = artifacts.require("JosephUsdt");
const JosephUsdc = artifacts.require("JosephUsdc");
const JosephDai = artifacts.require("JosephDai");
const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");
const CockpitDataProvider = artifacts.require("CockpitDataProvider");
const MiltonFacadeDataProvider = artifacts.require("MiltonFacadeDataProvider");

module.exports = async function (deployer, _network) {
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

    const iporOracleFacadeDataProvider = await deployProxy(
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
