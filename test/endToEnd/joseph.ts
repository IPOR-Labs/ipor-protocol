import hre, { upgrades } from "hardhat";

import { JosephUsdt, JosephUsdc, JosephDai } from "../../types";
import { usdtAddress, usdcAddress, daiAddress } from "./tokens";

export const josephDaiFactory = async (
    ipTokenDaiAddress: string,
    miltonDaiAddress: string,
    miltonStorageDaiAddress: string,
    stanleyDaiAddress: string
): Promise<JosephDai> => {
    const [admin] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("JosephDai", admin);
    return upgrades.deployProxy(
        factory,
        [
            daiAddress,
            ipTokenDaiAddress,
            miltonDaiAddress,
            miltonStorageDaiAddress,
            stanleyDaiAddress,
        ],
        {
            kind: "uups",
        }
    ) as Promise<JosephDai>;
};

export const josephUsdcFactory = async (
    ipTokenUsdcAddress: string,
    miltonUsdcAddress: string,
    miltonStorageUsdcAddress: string,
    stanleyUsdcAddress: string
): Promise<JosephUsdc> => {
    const [admin] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("JosephUsdc", admin);
    return upgrades.deployProxy(
        factory,
        [
            usdcAddress,
            ipTokenUsdcAddress,
            miltonUsdcAddress,
            miltonStorageUsdcAddress,
            stanleyUsdcAddress,
        ],
        {
            kind: "uups",
        }
    ) as Promise<JosephUsdc>;
};

export const josephUsdtFactory = async (
    ipTokenUsdtAddress: string,
    miltonUsdtAddress: string,
    miltonStorageUsdtAddress: string,
    stanleyUsdtAddress: string
): Promise<JosephUsdt> => {
    const [admin] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("JosephUsdt", admin);
    return upgrades.deployProxy(
        factory,
        [
            usdtAddress,
            ipTokenUsdtAddress,
            miltonUsdtAddress,
            miltonStorageUsdtAddress,
            stanleyUsdtAddress,
        ],
        {
            kind: "uups",
        }
    ) as Promise<JosephUsdt>;
};
