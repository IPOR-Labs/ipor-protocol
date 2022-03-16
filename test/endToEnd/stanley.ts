import hre from "hardhat";

import { daiAddress, usdcAddress, usdtAddress } from "./tokens";

import { StanleyDai, StanleyUsdc, StanleyUsdt } from "../../types";

export const stanleyDaiFactory = async (
    ivTokenDaiAddress: string,
    aaveStrategyDaiAddress: string,
    compoundStrategyDaiAddress: string
): Promise<StanleyDai> => {
    const [admin] = await hre.ethers.getSigners();
    const stanleyFactory = await hre.ethers.getContractFactory("StanleyDai", admin);
    return (await await upgrades.deployProxy(
        stanleyFactory,
        [daiAddress, ivTokenDaiAddress, aaveStrategyDaiAddress, compoundStrategyDaiAddress],
        {
            kind: "uups",
        }
    )) as Promise<StanleyDai>;
};

export const stanleyUsdcFactory = async (
    ivTokenUsdcAddress: string,
    aaveStrategyUsdcAddress: string,
    compoundStrategyUsdcAddress: string
): Promise<StanleyUsdc> => {
    const [admin] = await hre.ethers.getSigners();
    const stanleyFactory = await hre.ethers.getContractFactory("StanleyUsdc", admin);
    return (await await upgrades.deployProxy(
        stanleyFactory,
        [usdcAddress, ivTokenUsdcAddress, aaveStrategyUsdcAddress, compoundStrategyUsdcAddress],
        {
            kind: "uups",
        }
    )) as Promise<StanleyUsdc>;
};

export const stanleyUsdtFactory = async (
    ivTokenUsdtAddress: string,
    aaveStrategyUsdtAddress: string,
    compoundStrategyUsdtAddress: string
): Promise<StanleyUsdt> => {
    const [admin] = await hre.ethers.getSigners();
    const stanleyFactory = await hre.ethers.getContractFactory("StanleyUsdt", admin);
    return (await await upgrades.deployProxy(
        stanleyFactory,
        [usdtAddress, ivTokenUsdtAddress, aaveStrategyUsdtAddress, compoundStrategyUsdtAddress],
        {
            kind: "uups",
        }
    )) as Promise<StanleyUsdt>;
};

export const stanleySetup = async (
    stanley: StanleyDai | StanleyUsdc | StanleyUsdt,
    miltonAddress: string
) => {
    await stanley.setMilton(miltonAddress);
};
