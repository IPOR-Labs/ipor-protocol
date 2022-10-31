import hre, { upgrades } from "hardhat";

import { daiAddress, usdcAddress, usdtAddress } from "./tokens";

import { StanleyDai, StanleyUsdc, StanleyUsdt } from "../../types";

export const stanleyDaiFactory = async (
    ivTokenDaiAddress: string,
    strategyAaveDaiAddress: string,
    strategyCompoundDaiAddress: string
): Promise<StanleyDai> => {
    const [admin] = await hre.ethers.getSigners();
    const stanleyFactory = await hre.ethers.getContractFactory("StanleyDai", admin);
    return (await upgrades.deployProxy(
        stanleyFactory,
        [daiAddress, ivTokenDaiAddress, strategyAaveDaiAddress, strategyCompoundDaiAddress],
        {
            kind: "uups",
        }
    )) as StanleyDai;
};

export const stanleyUsdcFactory = async (
    ivTokenUsdcAddress: string,
    strategyAaveUsdcAddress: string,
    strategyCompoundUsdcAddress: string
): Promise<StanleyUsdc> => {
    const [admin] = await hre.ethers.getSigners();
    const stanleyFactory = await hre.ethers.getContractFactory("StanleyUsdc", admin);
    return (await upgrades.deployProxy(
        stanleyFactory,
        [usdcAddress, ivTokenUsdcAddress, strategyAaveUsdcAddress, strategyCompoundUsdcAddress],
        {
            kind: "uups",
        }
    )) as StanleyUsdc;
};

export const stanleyUsdtFactory = async (
    ivTokenUsdtAddress: string,
    strategyAaveUsdtAddress: string,
    strategyCompoundUsdtAddress: string
): Promise<StanleyUsdt> => {
    const [admin] = await hre.ethers.getSigners();
    const stanleyFactory = await hre.ethers.getContractFactory("StanleyUsdt", admin);
    return (await upgrades.deployProxy(
        stanleyFactory,
        [usdtAddress, ivTokenUsdtAddress, strategyAaveUsdtAddress, strategyCompoundUsdtAddress],
        {
            kind: "uups",
        }
    )) as StanleyUsdt;
};

export const stanleySetup = async (
    stanley: StanleyDai | StanleyUsdc | StanleyUsdt,
    miltonAddress: string
) => {
    await stanley.setMilton(miltonAddress);
};
