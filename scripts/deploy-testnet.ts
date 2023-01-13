import { ethers, upgrades } from "hardhat";

import {
    TestnetFaucet,
    MockTestnetTokenUsdt,
    MockTestnetTokenUsdc,
    MockTestnetTokenDai,
    MockTestnetShareTokenAaveUsdt,
    MockTestnetShareTokenAaveUsdc,
    MockTestnetShareTokenAaveDai,
    MockTestnetShareTokenCompoundUsdt,
    MockTestnetShareTokenCompoundUsdc,
    MockTestnetShareTokenCompoundDai,
    MockTestnetStrategyAaveUsdt,
    MockTestnetStrategyAaveUsdc,
    MockTestnetStrategyAaveDai,
    MockTestnetStrategyCompoundUsdt,
    MockTestnetStrategyCompoundUsdc,
    MockTestnetStrategyCompoundDai,
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
    Multicall2,
    IporToken,
    MockIporWeighted,
} from "../types";

async function main() {
    const [deployer] = await ethers.getSigners();

    const stableTotalSupply6Decimals = "1000000000000000000";
    const stableTotalSupply18Decimals = "1000000000000000000000000000000";
    const faucetInitialStable6Decimals = ethers.BigNumber.from("100000000000000000");
    const faucetInitialStable18Decimals = ethers.BigNumber.from("100000000000000000000000000000");
    const strategyInitialStable6Decimals = BigInt("1000000000000");
    const strategyInitialStable18Decimals = BigInt("1000000000000000000000000");

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

    const MockTestnetTokenUsdtFactory = await ethers.getContractFactory(
        "MockTestnetTokenUsdt",
        deployer
    );
    const MockTestnetTokenUsdcFactory = await ethers.getContractFactory(
        "MockTestnetTokenUsdc",
        deployer
    );
    const MockTestnetTokenDaiFactory = await ethers.getContractFactory(
        "MockTestnetTokenDai",
        deployer
    );

    const MockTestnetShareTokenAaveUsdtFactory = await ethers.getContractFactory(
        "MockTestnetShareTokenAaveUsdt",
        deployer
    );
    const MockTestnetShareTokenAaveUsdcFactory = await ethers.getContractFactory(
        "MockTestnetShareTokenAaveUsdc",
        deployer
    );
    const MockTestnetShareTokenAaveDaiFactory = await ethers.getContractFactory(
        "MockTestnetShareTokenAaveDai",
        deployer
    );

    const MockTestnetShareTokenCompoundUsdtFactory = await ethers.getContractFactory(
        "MockTestnetShareTokenCompoundUsdt",
        deployer
    );
    const MockTestnetShareTokenCompoundUsdcFactory = await ethers.getContractFactory(
        "MockTestnetShareTokenCompoundUsdc",
        deployer
    );
    const MockTestnetShareTokenCompoundDaiFactory = await ethers.getContractFactory(
        "MockTestnetShareTokenCompoundDai",
        deployer
    );

    const MockTestnetStrategyAaveUsdtFactory = await ethers.getContractFactory(
        "MockTestnetStrategyAaveUsdt",
        deployer
    );
    const MockTestnetStrategyAaveUsdcFactory = await ethers.getContractFactory(
        "MockTestnetStrategyAaveUsdc",
        deployer
    );
    const MockTestnetStrategyAaveDaiFactory = await ethers.getContractFactory(
        "MockTestnetStrategyAaveDai",
        deployer
    );

    const MockTestnetStrategyCompoundUsdtFactory = await ethers.getContractFactory(
        "MockTestnetStrategyCompoundUsdt",
        deployer
    );
    const MockTestnetStrategyCompoundUsdcFactory = await ethers.getContractFactory(
        "MockTestnetStrategyCompoundUsdc",
        deployer
    );
    const MockTestnetStrategyCompoundDaiFactory = await ethers.getContractFactory(
        "MockTestnetStrategyCompoundDai",
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
    const MockIporWeightedFactory = await ethers.getContractFactory("MockIporWeighted", deployer);

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

    const Multicall2Factory = await ethers.getContractFactory("Multicall2", deployer);

    const IporTokenFactory = await ethers.getContractFactory("IporToken", deployer);

    const mockedUsdt = (await MockTestnetTokenUsdtFactory.deploy(
        stableTotalSupply6Decimals
    )) as MockTestnetTokenUsdt;
    await mockedUsdt.deployed();

    const mockedUsdc = (await MockTestnetTokenUsdcFactory.deploy(
        stableTotalSupply6Decimals
    )) as MockTestnetTokenUsdc;
    await mockedUsdc.deployed();

    const mockedDai = (await MockTestnetTokenDaiFactory.deploy(
        stableTotalSupply18Decimals
    )) as MockTestnetTokenDai;
    await mockedDai.deployed();

    const mockTestnetShareTokenAaveUsdt = (await MockTestnetShareTokenAaveUsdtFactory.deploy(
        0
    )) as MockTestnetShareTokenAaveUsdt;
    await mockTestnetShareTokenAaveUsdt.deployed();

    const mockTestnetShareTokenAaveUsdc = (await MockTestnetShareTokenAaveUsdcFactory.deploy(
        0
    )) as MockTestnetShareTokenAaveUsdc;
    await mockTestnetShareTokenAaveUsdc.deployed();

    const mockTestnetShareTokenAaveDai = (await MockTestnetShareTokenAaveDaiFactory.deploy(
        0
    )) as MockTestnetShareTokenAaveDai;
    await mockTestnetShareTokenAaveDai.deployed();

    const mockTestnetShareTokenCompoundUsdt =
        (await MockTestnetShareTokenCompoundUsdtFactory.deploy(
            0
        )) as MockTestnetShareTokenCompoundUsdt;
    await mockTestnetShareTokenCompoundUsdt.deployed();

    const mockTestnetShareTokenCompoundUsdc =
        (await MockTestnetShareTokenCompoundUsdcFactory.deploy(
            0
        )) as MockTestnetShareTokenCompoundUsdc;
    await mockTestnetShareTokenCompoundUsdc.deployed();

    const mockTestnetShareTokenCompoundDai = (await MockTestnetShareTokenCompoundDaiFactory.deploy(
        0
    )) as MockTestnetShareTokenCompoundDai;
    await mockTestnetShareTokenCompoundDai.deployed();

    const mockTestnetStrategyAaveUsdtProxy = (await upgrades.deployProxy(
        MockTestnetStrategyAaveUsdtFactory,
        [mockedUsdt.address, mockTestnetShareTokenAaveUsdt.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MockTestnetStrategyAaveUsdt;
    await mockTestnetStrategyAaveUsdtProxy.deployed();

    const mockTestnetStrategyAaveUsdcProxy = (await upgrades.deployProxy(
        MockTestnetStrategyAaveUsdcFactory,
        [mockedUsdc.address, mockTestnetShareTokenAaveUsdc.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MockTestnetStrategyAaveUsdc;
    await mockTestnetStrategyAaveUsdcProxy.deployed();

    const mockTestnetStrategyAaveDaiProxy = (await upgrades.deployProxy(
        MockTestnetStrategyAaveDaiFactory,
        [mockedDai.address, mockTestnetShareTokenAaveDai.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MockTestnetStrategyAaveDai;
    await mockTestnetStrategyAaveDaiProxy.deployed();

    const mockTestnetStrategyCompoundUsdtProxy = (await upgrades.deployProxy(
        MockTestnetStrategyCompoundUsdtFactory,
        [mockedUsdt.address, mockTestnetShareTokenCompoundUsdt.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MockTestnetStrategyCompoundUsdt;
    await mockTestnetStrategyCompoundUsdtProxy.deployed();

    const mockTestnetStrategyCompoundUsdcProxy = (await upgrades.deployProxy(
        MockTestnetStrategyCompoundUsdcFactory,
        [mockedUsdc.address, mockTestnetShareTokenCompoundUsdc.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MockTestnetStrategyCompoundUsdc;
    await mockTestnetStrategyCompoundUsdcProxy.deployed();

    const mockTestnetStrategyCompoundDaiProxy = (await upgrades.deployProxy(
        MockTestnetStrategyCompoundDaiFactory,
        [mockedDai.address, mockTestnetShareTokenCompoundDai.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MockTestnetStrategyCompoundDai;
    await mockTestnetStrategyCompoundDaiProxy.deployed();

    const ipTokenUsdt = (await IpTokenUsdtFactory.deploy(
        "IP USDT",
        "ipUSDT",
        mockedUsdt.address
    )) as IpTokenUsdt;
    await ipTokenUsdt.deployed();

    const ipTokenUsdc = (await IpTokenUsdcFactory.deploy(
        "IP USDC",
        "ipUSDC",
        mockedUsdc.address
    )) as IpTokenUsdc;
    await ipTokenUsdc.deployed();

    const ipTokenDai = (await IpTokenDaiFactory.deploy(
        "IP DAI",
        "ipDAI",
        mockedDai.address
    )) as IpTokenDai;
    await ipTokenDai.deployed();

    const ivTokenUsdt = (await IvTokenUsdtFactory.deploy(
        "IV USDT",
        "ivUSDT",
        mockedUsdt.address
    )) as IvTokenUsdt;
    await ivTokenUsdt.deployed();

    const ivTokenUsdc = (await IvTokenUsdcFactory.deploy(
        "IV USDC",
        "ivUSDC",
        mockedUsdc.address
    )) as IvTokenUsdc;
    await ivTokenUsdc.deployed();

    const ivTokenDai = (await IvTokenDaiFactory.deploy(
        "IV DAI",
        "ivDAI",
        mockedDai.address
    )) as IvTokenDai;
    await ivTokenDai.deployed();

    const iporToken = (await IporTokenFactory.deploy(
        "IPOR Token",
        "IPOR",
        deployer.address
    )) as IporToken;
    await iporToken.deployed();

    const TestnetFaucetFactory = await ethers.getContractFactory("TestnetFaucet", deployer);
    const testnetFaucetProxy = (await upgrades.deployProxy(
        TestnetFaucetFactory,
        [mockedDai.address, mockedUsdc.address, mockedUsdt.address, iporToken.address],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as TestnetFaucet;
    await testnetFaucetProxy.deployed();

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
            [mockedUsdt.address, mockedUsdc.address, mockedDai.address],
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

    const iporAlgorithmProxy = (await upgrades.deployProxy(
        MockIporWeightedFactory,
        [iporOracleProxy],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as MockIporWeighted;

    await iporAlgorithmProxy.deployed();

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
            mockedUsdt.address,
            ivTokenUsdt.address,
            mockTestnetStrategyAaveUsdtProxy.address,
            mockTestnetStrategyCompoundUsdtProxy.address,
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
            mockedUsdc.address,
            ivTokenUsdc.address,
            mockTestnetStrategyAaveUsdcProxy.address,
            mockTestnetStrategyCompoundUsdcProxy.address,
        ],
        {
            initializer: "initialize",
            kind: "uups",
        }
    )) as StanleyUsdc;
    await stanleyUsdcProxy.deployed();

    const stanleyDaiProxy = (await upgrades.deployProxy(
        StanleyDaiFactory,
        [
            mockedDai.address,
            ivTokenDai.address,
            mockTestnetStrategyAaveDaiProxy.address,
            mockTestnetStrategyCompoundDaiProxy.address,
        ],
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
            mockedUsdt.address,
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
            mockedUsdc.address,
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
            mockedDai.address,
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
            mockedUsdt.address,
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
            mockedUsdc.address,
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
            mockedDai.address,
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
        [[mockedUsdt.address, mockedUsdc.address, mockedDai.address], iporOracleProxy.address],
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
            [mockedUsdt.address, mockedUsdc.address, mockedDai.address],
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
            [mockedUsdt.address, mockedUsdc.address, mockedDai.address],
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

    const multicall = (await Multicall2Factory.deploy()) as Multicall2;
    await multicall.deployed();

    await ipTokenUsdt.setJoseph(josephUsdtProxy.address);
    await ipTokenUsdc.setJoseph(josephUsdcProxy.address);
    await ipTokenDai.setJoseph(josephDaiProxy.address);

    await ivTokenUsdt.setStanley(stanleyUsdtProxy.address);
    await ivTokenUsdc.setStanley(stanleyUsdcProxy.address);
    await ivTokenDai.setStanley(stanleyDaiProxy.address);

    await miltonUsdtProxy.setJoseph(josephUsdtProxy.address);
    await miltonUsdtProxy.setupMaxAllowanceForAsset(josephUsdtProxy.address);
    await miltonUsdtProxy.setupMaxAllowanceForAsset(stanleyUsdtProxy.address);
    await miltonUsdtProxy.setAutoUpdateIporIndexThreshold(50);

    await miltonUsdcProxy.setJoseph(josephUsdcProxy.address);
    await miltonUsdcProxy.setupMaxAllowanceForAsset(josephUsdcProxy.address);
    await miltonUsdcProxy.setupMaxAllowanceForAsset(stanleyUsdcProxy.address);
    await miltonUsdcProxy.setAutoUpdateIporIndexThreshold(50);

    await miltonDaiProxy.setJoseph(josephDaiProxy.address);
    await miltonDaiProxy.setupMaxAllowanceForAsset(josephDaiProxy.address);
    await miltonDaiProxy.setupMaxAllowanceForAsset(stanleyDaiProxy.address);
    await miltonDaiProxy.setAutoUpdateIporIndexThreshold(50);

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
    await iporOracleProxy.setIporAlgorithmFacade(iporAlgorithmProxy.address);

    await mockTestnetStrategyAaveUsdtProxy.setStanley(stanleyUsdtProxy.address);
    await mockTestnetStrategyAaveUsdcProxy.setStanley(stanleyUsdcProxy.address);
    await mockTestnetStrategyAaveDaiProxy.setStanley(stanleyDaiProxy.address);

    await mockTestnetStrategyCompoundUsdtProxy.setStanley(stanleyUsdtProxy.address);
    await mockTestnetStrategyCompoundUsdcProxy.setStanley(stanleyUsdcProxy.address);
    await mockTestnetStrategyCompoundDaiProxy.setStanley(stanleyDaiProxy.address);

    await deployer.sendTransaction({
        to: testnetFaucetProxy.address,
        value: ethers.utils.parseEther("1.0"),
    });

    await mockedUsdt.transfer(testnetFaucetProxy.address, faucetInitialStable6Decimals);
    await mockedUsdc.transfer(testnetFaucetProxy.address, faucetInitialStable6Decimals);
    await mockedDai.transfer(testnetFaucetProxy.address, faucetInitialStable18Decimals);

    await mockedUsdt.transfer(
        mockTestnetStrategyAaveUsdtProxy.address,
        strategyInitialStable6Decimals
    );
    await mockedUsdc.transfer(
        mockTestnetStrategyAaveUsdcProxy.address,
        strategyInitialStable6Decimals
    );
    await mockedDai.transfer(
        mockTestnetStrategyAaveDaiProxy.address,
        strategyInitialStable18Decimals
    );

    await mockedUsdt.transfer(
        mockTestnetStrategyCompoundUsdtProxy.address,
        strategyInitialStable6Decimals
    );
    await mockedUsdc.transfer(
        mockTestnetStrategyCompoundUsdcProxy.address,
        strategyInitialStable6Decimals
    );
    await mockedDai.transfer(
        mockTestnetStrategyCompoundDaiProxy.address,
        strategyInitialStable18Decimals
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
