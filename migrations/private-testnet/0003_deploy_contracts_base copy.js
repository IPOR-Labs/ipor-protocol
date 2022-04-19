// require("dotenv").config({ path: "../.env" });

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

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

module.exports = async function (deployer, _network) {

    await deployer.deploy(MiltonSpreadModel);
    const miltonSpreadModel = await MiltonSpreadModel.deployed();

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

	console.log ("Strategy Aaave USDT: ", erc1967.getImplementationAddress(strategyAaveUsdt.address);

	

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
