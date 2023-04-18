import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";

import {
    Milton,
    TestnetFaucet,
    MiltonStorageUsdt,
    MiltonStorageUsdc,
    MiltonStorageDai,
    MiltonSpreadModelUsdt,
    MiltonSpreadModelUsdc,
    MiltonSpreadModelDai,
    MiltonUsdt,
    MiltonUsdc,
    MiltonDai,
    Joseph,
    JosephUsdt,
    JosephUsdc,
    JosephDai,
    Stanley,
    StanleyUsdt,
    StanleyUsdc,
    StanleyDai,
    MiltonStorage,
    ERC20,
    IporOracle,
    MiltonFacadeDataProvider,
} from "../../types";
import {
    usdtAddress,
    usdcAddress,
    daiAddress,
    transferUsdtToAddress,
    transferUsdcToAddress,
    transferDaiToAddress,
} from "./tokens";

const faucetSupply6Decimals = BigNumber.from("10000000000000");
const faucetSupply18Decimals = BigNumber.from("100000000000000000000000");
export const testnetFaucetFactory = async (): Promise<TestnetFaucet> => {
    const TestnetFaucetFactory = await hre.ethers.getContractFactory("TestnetFaucet");
    return TestnetFaucetFactory.deploy() as Promise<TestnetFaucet>;
};

export const testnetFaucetSetup = async (
    testnetFaucet: TestnetFaucet,
    dai: ERC20,
    usdc: ERC20,
    usdt: ERC20
) => {
    await hre.network.provider.send("hardhat_setBalance", [
        testnetFaucet.address,
        "0x500000000000000000000",
    ]);
    await transferDaiToAddress(
        "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7",
        testnetFaucet.address,
        faucetSupply18Decimals
    );
    await transferUsdcToAddress(
        "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7",
        testnetFaucet.address,
        faucetSupply6Decimals
    );
    await transferUsdtToAddress(
        "0x5754284f345afc66a98fbb0a0afe71e0f007b949",
        testnetFaucet.address,
        faucetSupply6Decimals
    );
};

export const transferFromFaucetTo = async (
    testnetFaucet: TestnetFaucet,
    asset: ERC20,
    to: string,
    amount: BigNumber
) => {
    if (asset.address === daiAddress) {
        await transferDaiToAddress(testnetFaucet.address, to, amount);
        return;
    }
    if (asset.address === usdcAddress) {
        await transferUsdcToAddress(testnetFaucet.address, to, amount);
        return;
    }
    if (asset.address === usdtAddress) {
        await transferUsdtToAddress(testnetFaucet.address, to, amount);
        return;
    }
};

export const miltonStorageDaiFactory = async (): Promise<MiltonStorageDai> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonStorageFactory = await hre.ethers.getContractFactory("MiltonStorageDai", admin);
    return upgrades.deployProxy(miltonStorageFactory, [], {
        kind: "uups",
    }) as Promise<MiltonStorageDai>;
};

export const miltonStorageUsdcFactory = async (): Promise<MiltonStorageUsdc> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonStorageFactory = await hre.ethers.getContractFactory("MiltonStorageUsdc", admin);
    return upgrades.deployProxy(miltonStorageFactory, [], {
        kind: "uups",
    }) as Promise<MiltonStorageUsdc>;
};

export const miltonStorageUsdtFactory = async (): Promise<MiltonStorageUsdt> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonStorageFactory = await hre.ethers.getContractFactory("MiltonStorageUsdt", admin);
    return upgrades.deployProxy(miltonStorageFactory, [], {
        kind: "uups",
    }) as Promise<MiltonStorageUsdt>;
};

export const miltonSpreadModelUsdtFactory = async (): Promise<MiltonSpreadModelUsdt> => {
    const [admin] = await hre.ethers.getSigners();
    const spreadModelFactory = await hre.ethers.getContractFactory("MiltonSpreadModelUsdt");
    return (await spreadModelFactory.deploy()) as MiltonSpreadModelUsdt;
};
export const miltonSpreadModelUsdcFactory = async (): Promise<MiltonSpreadModelUsdc> => {
    const [admin] = await hre.ethers.getSigners();
    const spreadModelFactory = await hre.ethers.getContractFactory("MiltonSpreadModelUsdc");
    return (await spreadModelFactory.deploy()) as MiltonSpreadModelUsdc;
};
export const miltonSpreadModelDaiFactory = async (): Promise<MiltonSpreadModelDai> => {
    const [admin] = await hre.ethers.getSigners();
    const spreadModelFactory = await hre.ethers.getContractFactory("MiltonSpreadModelDai");
    return (await spreadModelFactory.deploy()) as MiltonSpreadModelDai;
};

export const miltonUsdtFactory = async (
    iporOracleAddress: string,
    miltonStorageUsdtAddress: string,
    miltonSpreadModelAddress: string,
    stanleyUsdtAddress: string,
    marketSafetyOracleAddress: string
): Promise<MiltonUsdt> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonFactory = await hre.ethers.getContractFactory("MiltonUsdt", admin);
    return upgrades.deployProxy(
        miltonFactory,
        [
            false,
            usdtAddress,
            iporOracleAddress,
            miltonStorageUsdtAddress,
            miltonSpreadModelAddress,
            stanleyUsdtAddress,
        ],
        {
            kind: "uups",
            constructorArgs: [
                marketSafetyOracleAddress,
            ]
        }
    ) as Promise<MiltonUsdt>;
};

export const miltonUsdcFactory = async (
    iporOracleAddress: string,
    miltonStorageUsdcAddress: string,
    miltonSpreadModelAddress: string,
    stanleyUsdcAddress: string,
    marketSafetyOracleAddress: string
): Promise<MiltonUsdc> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonFactory = await hre.ethers.getContractFactory("MiltonUsdc", admin);
    return upgrades.deployProxy(
        miltonFactory,
        [
            false,
            usdcAddress,
            iporOracleAddress,
            miltonStorageUsdcAddress,
            miltonSpreadModelAddress,
            stanleyUsdcAddress,
        ],
        {
            kind: "uups",
            constructorArgs: [
                marketSafetyOracleAddress,
            ]
        }
    ) as Promise<MiltonUsdc>;
};

export const miltonDaiFactory = async (
    iporOracleAddress: string,
    miltonStorageDaiAddress: string,
    miltonSpreadModelAddress: string,
    stanleyDaiAddress: string,
    marketSafetyOracleAddress: string
): Promise<MiltonDai> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonFactory = await hre.ethers.getContractFactory("MiltonDai", admin);
    return upgrades.deployProxy(
        miltonFactory,
        [
            false,
            daiAddress,
            iporOracleAddress,
            miltonStorageDaiAddress,
            miltonSpreadModelAddress,
            stanleyDaiAddress,
        ],
        {
            kind: "uups",
            constructorArgs: [
                marketSafetyOracleAddress,
            ]
        }
    ) as Promise<MiltonDai>;
};

export const miltonFacadeDataProviderFactory = async (
    dai: ERC20,
    usdc: ERC20,
    usdt: ERC20,
    miltonDai: MiltonDai,
    miltonUsdc: MiltonUsdc,
    miltonUsdt: MiltonUsdt,
    miltonStorageDai: MiltonStorageDai,
    miltonStorageUsdc: MiltonStorageUsdc,
    miltonStorageUsdt: MiltonStorageUsdt,
    josephUsdt: JosephUsdt,
    josephUsdc: JosephUsdc,
    josephDai: JosephDai,
    iporOracle: IporOracle
): Promise<MiltonFacadeDataProvider> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonFacadeDataProvider = await hre.ethers.getContractFactory(
        "MiltonFacadeDataProvider",
        admin
    );
    return upgrades.deployProxy(
        miltonFacadeDataProvider,
        [
            iporOracle.address,
            [usdt.address, usdc.address, dai.address],
            [miltonUsdt.address, miltonUsdc.address, miltonDai.address],
            [miltonStorageUsdt.address, miltonStorageUsdc.address, miltonStorageDai.address],
            [josephUsdt.address, josephUsdc.address, josephDai.address],
        ],
        {
            kind: "uups",
        }
    ) as Promise<MiltonFacadeDataProvider>;
};

export const miltonSetup = async (
    milton: Milton | MiltonDai | MiltonUsdc | MiltonUsdt,
    joseph: Joseph | JosephDai | JosephUsdc | JosephUsdt,
    stanley: Stanley | StanleyDai | StanleyUsdc | StanleyUsdt
) => {
    await milton.setJoseph(joseph.address);
    await milton.setupMaxAllowanceForAsset(joseph.address);
    await milton.setupMaxAllowanceForAsset(stanley.address);
};
export const miltonStorageSetup = async (
    miltonStorage: MiltonStorage | MiltonStorageDai | MiltonStorageUsdc | MiltonStorageUsdt,
    milton: Milton | MiltonDai | MiltonUsdc | MiltonUsdt,
    joseph: Joseph | JosephDai | JosephUsdc | JosephUsdt
) => {
    await miltonStorage.setJoseph(joseph.address);
    await miltonStorage.setMilton(milton.address);
};
