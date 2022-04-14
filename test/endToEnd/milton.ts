import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";

import {
    Milton,
    MiltonFaucet,
    MiltonStorageUsdc,
    MiltonStorageUsdt,
    MiltonStorageDai,
    MiltonSpreadModel,
    MiltonUsdc,
    MiltonUsdt,
    MiltonDai,
    Joseph,
    JosephDai,
    JosephUsdc,
    JosephUsdt,
    Stanley,
    StanleyDai,
    StanleyUsdc,
    StanleyUsdt,
    MiltonStorage,
    ERC20,
    IporOracle,
    MiltonFacadeDataProvider,
} from "../../types";
import {
    usdtAddress,
    usdcAddress,
    daiAddress,
    transferDaiToAddress,
    transferUsdcToAddress,
    transferUsdtToAddress,
} from "./tokens";

const faucetSupply6Decimals = BigNumber.from("1000000000000000");
const faucetSupply18Decimals = BigNumber.from("1000000000000000000000000000");
export const miltonFaucetFactory = async (): Promise<MiltonFaucet> => {
    const MiltonFaucetFactory = await hre.ethers.getContractFactory("MiltonFaucet");
    return MiltonFaucetFactory.deploy() as Promise<MiltonFaucet>;
};

export const miltonFaucetSetup = async (
    miltonFaucet: MiltonFaucet,
    dai: ERC20,
    usdc: ERC20,
    usdt: ERC20
) => {
    await hre.network.provider.send("hardhat_setBalance", [
        miltonFaucet.address,
        "0x500000000000000000000",
    ]);
    await transferDaiToAddress(
        "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7",
        miltonFaucet.address,
        faucetSupply18Decimals
    );
    console.log(
        "daiAddress -> balanseOf -> miltonFaucet",
        await dai.balanceOf(miltonFaucet.address)
    );
    await transferUsdcToAddress(
        "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7",
        miltonFaucet.address,
        faucetSupply6Decimals
    );
    console.log(
        "usdcAddress -> balanseOf -> miltonFaucet",
        await usdc.balanceOf(miltonFaucet.address)
    );
    await transferUsdtToAddress(
        "0x5754284f345afc66a98fbb0a0afe71e0f007b949",
        miltonFaucet.address,
        faucetSupply6Decimals
    );
    console.log(
        "usdtAddress -> balanseOf -> miltonFaucet",
        await usdt.balanceOf(miltonFaucet.address)
    );
};

export const transferFromFaucetTo = async (
    miltonFaucet: MiltonFaucet,
    asset: ERC20,
    to: string,
    amound: BigNumber
) => {
    if (asset.address === daiAddress) {
        await transferDaiToAddress(miltonFaucet.address, to, amound);
        return;
    }
    if (asset.address === usdcAddress) {
        await transferUsdcToAddress(miltonFaucet.address, to, amound);
        return;
    }
    if (asset.address === usdtAddress) {
        await transferUsdtToAddress(miltonFaucet.address, to, amound);
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

export const miltonSpreadModelFactory = async (): Promise<MiltonSpreadModel> => {
    const [admin] = await hre.ethers.getSigners();
    const spreadModelFactory = await hre.ethers.getContractFactory("MiltonSpreadModel");
    return (await spreadModelFactory.deploy()) as MiltonSpreadModel;
};

export const miltonUsdtFactory = async (
    iporOracleAddress: string,
    miltonStorageUsdtAddress: string,
    miltonSpreadModelAddress: string,
    stanleyUsdtAddress: string
): Promise<MiltonUsdt> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonFactory = await hre.ethers.getContractFactory("MiltonUsdt", admin);
    return upgrades.deployProxy(
        miltonFactory,
        [
            usdtAddress,
            iporOracleAddress,
            miltonStorageUsdtAddress,
            miltonSpreadModelAddress,
            stanleyUsdtAddress,
        ],
        {
            kind: "uups",
        }
    ) as Promise<MiltonUsdt>;
};

export const miltonUsdcFactory = async (
    iporOracleAddress: string,
    miltonStorageUsdcAddress: string,
    miltonSpreadModelAddress: string,
    stanleyUsdcAddress: string
): Promise<MiltonUsdc> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonFactory = await hre.ethers.getContractFactory("MiltonUsdc", admin);
    return upgrades.deployProxy(
        miltonFactory,
        [
            usdcAddress,
            iporOracleAddress,
            miltonStorageUsdcAddress,
            miltonSpreadModelAddress,
            stanleyUsdcAddress,
        ],
        {
            kind: "uups",
        }
    ) as Promise<MiltonUsdc>;
};

export const miltonDaiFactory = async (
    iporOracleAddress: string,
    miltonStorageDaiAddress: string,
    miltonSpreadModelAddress: string,
    stanleyDaiAddress: string
): Promise<MiltonDai> => {
    const [admin] = await hre.ethers.getSigners();
    const miltonFactory = await hre.ethers.getContractFactory("MiltonDai", admin);
    return upgrades.deployProxy(
        miltonFactory,
        [
            daiAddress,
            iporOracleAddress,
            miltonStorageDaiAddress,
            miltonSpreadModelAddress,
            stanleyDaiAddress,
        ],
        {
            kind: "uups",
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
