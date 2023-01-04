import { ethers, upgrades } from "hardhat";

import {
    StrategyAaveUsdt,
    StrategyAaveUsdc,
    StrategyAaveDai,
    StrategyCompoundUsdt,
    StrategyCompoundUsdc,
    StrategyCompoundDai,
    IpTokenUsdt,
    IpTokenUsdc,
    IpTokenDai,
    IvTokenUsdt,
    IvTokenUsdc,
    IvTokenDai,
    MiltonSpreadModelUsdt,
    MiltonSpreadModelUsdc,
    MiltonSpreadModelDai,
    IporOracle,
    MiltonStorageUsdt,
    MiltonStorageUsdc,
    MiltonStorageDai,
    StanleyUsdt,
    StanleyUsdc,
    StanleyDai,
    MiltonUsdt,
    MiltonUsdc,
    MiltonDai,
    JosephUsdt,
    JosephUsdc,
    JosephDai,
    IporOracleFacadeDataProvider,
    MiltonFacadeDataProvider,
    CockpitDataProvider,
    IporToken,
} from "../types";

const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const AAVE = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
const aUSDT = "0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811";
const aUSDC = "0xBcca60bB61934080951369a648Fb03DF4F96263C";
const aDAI = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";
const aaveProvider = "0xb53c1a33016b2dc2ff3653530bff1848a515c8c5";
const aaveStaked = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";
const aaveIncentivesController = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";
const COMP = "0xc00e94cb662c3520282e6f5717214004a7f26888";
const cUSDT = "0xf650c3d88d12db855b8bf7d11be6c55a4e07dcc9";
const cUSDC = "0x39aa39c021dfbae8fac545936693ac917d5e7563";
const cDAI = "0x5d3a536e4d6dbd6114cc1ead35777bab948e3643";
const comptroller = "0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b";

async function main() {
    const [deployer] = await ethers.getSigners();

    const updateTimestamps = [
        ethers.BigNumber.from("1660555769"),
        ethers.BigNumber.from("1660555769"),
        ethers.BigNumber.from("1660555761"),
    ];
    const exponentialMovingAverages = [
        ethers.BigNumber.from("20097500738300873"),
        ethers.BigNumber.from("11700180714644771"),
        ethers.BigNumber.from("14396144491640854"),
    ];
    const exponentialWeightedMovingVariances = [
        ethers.BigNumber.from("407529933285"),
        ethers.BigNumber.from("431497340438"),
        ethers.BigNumber.from("919780738286"),
    ];

    const StrategyAaveUsdtFactory = await ethers.getContractFactory("StrategyAaveUsdt", deployer);
    const StrategyAaveUsdcFactory = await ethers.getContractFactory("StrategyAaveUsdc", deployer);
    const StrategyAaveDaiFactory = await ethers.getContractFactory("StrategyAaveDai", deployer);

    const StrategyCompoundUsdtFactory = await ethers.getContractFactory(
        "StrategyCompoundUsdt",
        deployer
    );
    const StrategyCompoundUsdcFactory = await ethers.getContractFactory(
        "StrategyCompoundUsdc",
        deployer
    );
    const StrategyCompoundDaiFactory = await ethers.getContractFactory(
        "StrategyCompoundDai",
        deployer
    );

    const IpTokenUsdtFactory = await ethers.getContractFactory("IpTokenUsdt", deployer);
    const IpTokenUsdcFactory = await ethers.getContractFactory("IpTokenUsdc", deployer);
    const IpTokenDaiFactory = await ethers.getContractFactory("IpTokenDai", deployer);

    const IvTokenUsdtFactory = await ethers.getContractFactory("IvTokenUsdt", deployer);
    const IvTokenUsdcFactory = await ethers.getContractFactory("IvTokenUsdc", deployer);
    const IvTokenDaiFactory = await ethers.getContractFactory("IvTokenDai", deployer);

    const MiltonSpreadModelUsdtFactory = await ethers.getContractFactory(
        "MiltonSpreadModelUsdt",
        deployer
    );
    const MiltonSpreadModelUsdcFactory = await ethers.getContractFactory(
        "MiltonSpreadModelUsdc",
        deployer
    );
    const MiltonSpreadModelDaiFactory = await ethers.getContractFactory(
        "MiltonSpreadModelDai",
        deployer
    );

    const IporOracleFactory = await ethers.getContractFactory("IporOracle", deployer);

    const MiltonStorageUsdtFactory = await ethers.getContractFactory("MiltonStorageUsdt", deployer);
    const MiltonStorageUsdcFactory = await ethers.getContractFactory("MiltonStorageUsdc", deployer);
    const MiltonStorageDaiFactory = await ethers.getContractFactory("MiltonStorageDai", deployer);

    const StanleyUsdtFactory = await ethers.getContractFactory("StanleyUsdt", deployer);
    const StanleyUsdcFactory = await ethers.getContractFactory("StanleyUsdc", deployer);
    const StanleyDaiFactory = await ethers.getContractFactory("StanleyDai", deployer);

    const MiltonUsdtFactory = await ethers.getContractFactory("MiltonUsdt", deployer);
    const MiltonUsdcFactory = await ethers.getContractFactory("MiltonUsdc", deployer);
    const MiltonDaiFactory = await ethers.getContractFactory("MiltonDai", deployer);

    const JosephUsdtFactory = await ethers.getContractFactory("JosephUsdt", deployer);
    const JosephUsdcFactory = await ethers.getContractFactory("JosephUsdc", deployer);
    const JosephDaiFactory = await ethers.getContractFactory("JosephDai", deployer);

    const IporOracleFacadeDataProviderFactory = await ethers.getContractFactory(
        "IporOracleFacadeDataProvider",
        deployer
    );
    const MiltonFacadeDataProviderFactory = await ethers.getContractFactory(
        "MiltonFacadeDataProvider",
        deployer
    );
    const CockpitDataProviderFactory = await ethers.getContractFactory(
        "CockpitDataProvider",
        deployer
    );

    const IporTokenFactory = await ethers.getContractFactory("IporToken", deployer);

    const strategyAaveUsdtProxy = (await upgrades.deployProxy(
        StrategyAaveUsdtFactory,
        [USDT, aUSDT, aaveProvider, aaveStaked, aaveIncentivesController, AAVE],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StrategyAaveUsdt;
    await strategyAaveUsdtProxy.deployed();

    const strategyAaveUsdcProxy = (await upgrades.deployProxy(
        StrategyAaveUsdcFactory,
        [USDC, aUSDC, aaveProvider, aaveStaked, aaveIncentivesController, AAVE],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StrategyAaveUsdc;
    await strategyAaveUsdcProxy.deployed();

    const strategyAaveDaiProxy = (await upgrades.deployProxy(
        StrategyAaveDaiFactory,
        [DAI, aDAI, aaveProvider, aaveStaked, aaveIncentivesController, AAVE],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StrategyAaveDai;
    await strategyAaveDaiProxy.deployed();

    const strategyCompoundUsdtProxy = (await upgrades.deployProxy(
        StrategyCompoundUsdtFactory,
        [USDT, cUSDT, comptroller, COMP],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StrategyCompoundUsdt;
    await strategyCompoundUsdtProxy.deployed();

    const strategyCompoundUsdcProxy = (await upgrades.deployProxy(
        StrategyCompoundUsdcFactory,
        [USDC, cUSDC, comptroller, COMP],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StrategyCompoundUsdc;
    await strategyCompoundUsdcProxy.deployed();

    const strategyCompoundDaiProxy = (await upgrades.deployProxy(
        StrategyCompoundDaiFactory,
        [DAI, cDAI, comptroller, COMP],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StrategyCompoundDai;
    await strategyCompoundDaiProxy.deployed();

    const ipTokenUsdt = (await IpTokenUsdtFactory.deploy("IP USDT", "ipUSDT", USDT)) as IpTokenUsdt;
    await ipTokenUsdt.deployed();

    const ipTokenUsdc = (await IpTokenUsdcFactory.deploy("IP USDC", "ipUSDC", USDC)) as IpTokenUsdc;
    await ipTokenUsdc.deployed();

    const ipTokenDai = (await IpTokenDaiFactory.deploy("IP DAI", "ipDAI", DAI)) as IpTokenDai;
    await ipTokenDai.deployed();

    const ivTokenUsdt = (await IvTokenUsdtFactory.deploy("IV USDT", "ivUSDT", USDT)) as IvTokenUsdt;
    await ivTokenUsdt.deployed();

    const ivTokenUsdc = (await IvTokenUsdcFactory.deploy("IV USDC", "ivUSDC", USDC)) as IvTokenUsdc;
    await ivTokenUsdc.deployed();

    const ivTokenDai = (await IvTokenDaiFactory.deploy("IV DAI", "ivDAI", DAI)) as IvTokenDai;
    await ivTokenDai.deployed();

    const miltonSpreadModelUsdt =
        (await MiltonSpreadModelUsdtFactory.deploy()) as MiltonSpreadModelUsdt;
    await miltonSpreadModelUsdt.deployed();

    const miltonSpreadModelUsdc =
        (await MiltonSpreadModelUsdcFactory.deploy()) as MiltonSpreadModelUsdc;
    await miltonSpreadModelUsdc.deployed();

    const miltonSpreadModelDai =
        (await MiltonSpreadModelDaiFactory.deploy()) as MiltonSpreadModelDai;
    await miltonSpreadModelDai.deployed();

    const iporOracleProxy = (await upgrades.deployProxy(
        IporOracleFactory,
        [
            [USDT, USDC, DAI],
            updateTimestamps,
            exponentialMovingAverages,
            exponentialWeightedMovingVariances,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as IporOracle;
    await iporOracleProxy.deployed();

    const miltonStorageUsdtProxy = (await upgrades.deployProxy(MiltonStorageUsdtFactory, [], {
        initializer: "initialize",
        kind: "uups",
    })) as MiltonStorageUsdt;
    await miltonStorageUsdtProxy.deployed();

    const miltonStorageUsdcProxy = (await upgrades.deployProxy(MiltonStorageUsdcFactory, [], {
        initializer: "initialize",
        kind: "uups",
    })) as MiltonStorageUsdc;
    await miltonStorageUsdcProxy.deployed();

    const miltonStorageDaiProxy = (await upgrades.deployProxy(MiltonStorageDaiFactory, [], {
        initializer: "initialize",
        kind: "uups",
    })) as MiltonStorageDai;
    await miltonStorageDaiProxy.deployed();

    const stanleyUsdtProxy = (await upgrades.deployProxy(
        StanleyUsdtFactory,
        [
            USDT,
            ivTokenUsdt.address,
            strategyAaveUsdtProxy.address,
            strategyCompoundUsdtProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StanleyUsdt;
    await stanleyUsdtProxy.deployed();

    const stanleyUsdcProxy = (await upgrades.deployProxy(
        StanleyUsdcFactory,
        [
            USDC,
            ivTokenUsdc.address,
            strategyAaveUsdcProxy.address,
            strategyCompoundUsdcProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StanleyUsdc;
    await stanleyUsdcProxy.deployed();

    const stanleyDaiProxy = (await upgrades.deployProxy(
        StanleyDaiFactory,
        [DAI, ivTokenDai.address, strategyAaveDaiProxy.address, strategyCompoundDaiProxy.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StanleyDai;
    await stanleyDaiProxy.deployed();

    const miltonUsdtProxy = (await upgrades.deployProxy(
        MiltonUsdtFactory,
        [
            false,
            USDT,
            iporOracleProxy.address,
            miltonStorageUsdtProxy.address,
            miltonSpreadModelUsdt.address,
            stanleyUsdtProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MiltonUsdt;
    await miltonUsdtProxy.deployed();

    const miltonUsdcProxy = (await upgrades.deployProxy(
        MiltonUsdcFactory,
        [
            false,
            USDC,
            iporOracleProxy.address,
            miltonStorageUsdcProxy.address,
            miltonSpreadModelUsdc.address,
            stanleyUsdcProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MiltonUsdc;
    await miltonUsdcProxy.deployed();

    const miltonDaiProxy = (await upgrades.deployProxy(
        MiltonDaiFactory,
        [
            false,
            DAI,
            iporOracleProxy.address,
            miltonStorageDaiProxy.address,
            miltonSpreadModelDai.address,
            stanleyDaiProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MiltonDai;
    await miltonDaiProxy.deployed();

    const josephUsdtProxy = (await upgrades.deployProxy(
        JosephUsdtFactory,
        [
            false,
            USDT,
            ivTokenUsdt.address,
            miltonUsdtProxy.address,
            miltonStorageUsdtProxy.address,
            stanleyUsdtProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as JosephUsdt;
    await josephUsdtProxy.deployed();

    const josephUsdcProxy = (await upgrades.deployProxy(
        JosephUsdcFactory,
        [
            false,
            USDC,
            ivTokenUsdc.address,
            miltonUsdcProxy.address,
            miltonStorageUsdcProxy.address,
            stanleyUsdcProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as JosephUsdc;
    await josephUsdcProxy.deployed();

    const josephDaiProxy = (await upgrades.deployProxy(
        JosephDaiFactory,
        [
            false,
            DAI,
            ivTokenDai.address,
            miltonDaiProxy.address,
            miltonStorageDaiProxy.address,
            stanleyDaiProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as JosephDai;
    await josephDaiProxy.deployed();

    const iporOracleFacadeDataProviderProxy = (await upgrades.deployProxy(
        IporOracleFacadeDataProviderFactory,
        [[USDT, USDC, DAI], iporOracleProxy.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as IporOracleFacadeDataProvider;
    await iporOracleFacadeDataProviderProxy.deployed();

    const miltonFacadeDataProviderProxy = (await upgrades.deployProxy(
        MiltonFacadeDataProviderFactory,
        [
            iporOracleProxy.address,
            [USDT, USDC, DAI],
            [miltonUsdtProxy.address, miltonUsdcProxy.address, miltonDaiProxy.address],
            [
                miltonStorageUsdtProxy.address,
                miltonStorageUsdcProxy.address,
                miltonStorageDaiProxy.address,
            ],
            [josephUsdtProxy.address, josephUsdcProxy.address, josephDaiProxy.address],
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MiltonFacadeDataProvider;
    await miltonFacadeDataProviderProxy.deployed();

    const cockpitDataProviderProxy = (await upgrades.deployProxy(
        CockpitDataProviderFactory,
        [
            iporOracleProxy.address,
            [USDT, USDC, DAI],
            [miltonUsdtProxy.address, miltonUsdcProxy.address, miltonDaiProxy.address],
            [
                miltonStorageUsdtProxy.address,
                miltonStorageUsdcProxy.address,
                miltonStorageDaiProxy.address,
            ],
            [josephUsdtProxy.address, josephUsdcProxy.address, josephDaiProxy.address],
            [ipTokenUsdt.address, ipTokenUsdc.address, ipTokenDai.address],
            [ivTokenUsdt.address, ivTokenUsdc.address, ivTokenDai.address],
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as CockpitDataProvider;
    await cockpitDataProviderProxy.deployed();

    const iporToken = (await IporTokenFactory.deploy(
        "IPOR Token",
        "IPOR",
        deployer.address
    )) as IporToken;
    await iporToken.deployed();

    await ipTokenUsdt.setJoseph(josephUsdtProxy.address);
    await ipTokenUsdc.setJoseph(josephUsdcProxy.address);
    await ipTokenDai.setJoseph(josephDaiProxy.address);

    await ivTokenUsdt.setStanley(stanleyUsdtProxy.address);
    await ivTokenUsdc.setStanley(stanleyUsdcProxy.address);
    await ivTokenDai.setStanley(stanleyDaiProxy.address);

    await miltonUsdtProxy.setJoseph(josephUsdtProxy.address);
    await miltonUsdtProxy.setupMaxAllowanceForAsset(josephUsdtProxy.address);
    await miltonUsdtProxy.setupMaxAllowanceForAsset(stanleyUsdtProxy.address);

    await miltonUsdcProxy.setJoseph(josephUsdcProxy.address);
    await miltonUsdcProxy.setupMaxAllowanceForAsset(josephUsdcProxy.address);
    await miltonUsdcProxy.setupMaxAllowanceForAsset(stanleyUsdcProxy.address);

    await miltonDaiProxy.setJoseph(josephDaiProxy.address);
    await miltonDaiProxy.setupMaxAllowanceForAsset(josephDaiProxy.address);
    await miltonDaiProxy.setupMaxAllowanceForAsset(stanleyDaiProxy.address);

    await miltonStorageUsdtProxy.setJoseph(josephUsdtProxy.address);
    await miltonStorageUsdtProxy.setMilton(miltonUsdtProxy.address);

    await miltonStorageUsdcProxy.setJoseph(josephUsdcProxy.address);
    await miltonStorageUsdcProxy.setMilton(miltonUsdcProxy.address);

    await miltonStorageDaiProxy.setJoseph(josephDaiProxy.address);
    await miltonStorageDaiProxy.setMilton(miltonDaiProxy.address);

    await stanleyUsdtProxy.setMilton(miltonUsdtProxy.address);
    await stanleyUsdcProxy.setMilton(miltonUsdcProxy.address);
    await stanleyDaiProxy.setMilton(miltonDaiProxy.address);

    await iporOracleProxy.addUpdater(await deployer.getAddress());

    await strategyAaveUsdtProxy.setStanley(stanleyUsdtProxy.address);
    await strategyAaveUsdcProxy.setStanley(stanleyUsdcProxy.address);
    await strategyAaveDaiProxy.setStanley(stanleyDaiProxy.address);

    await strategyCompoundUsdtProxy.setStanley(stanleyUsdtProxy.address);
    await strategyCompoundUsdcProxy.setStanley(stanleyUsdcProxy.address);
    await strategyCompoundDaiProxy.setStanley(stanleyDaiProxy.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
