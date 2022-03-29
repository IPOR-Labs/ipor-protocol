import hre from "hardhat";

const daiComp = require("../../abis/compTokenAbi.json");
import {
    daiAddress,
    cDaiAddress,
    usdcAddress,
    cUsdcAddress,
    usdtAddress,
    cUsdtAddress,
} from "./tokens";

import { ERC20, StrategyCompound } from "../../types";

const comptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";
const compTokenAddress = "0xc00e94Cb662C3520282E6f5717214004A7f26888";

export const compTokenFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(compTokenAddress, daiComp, admin) as ERC20;
};

export const compoundDaiStrategyFactory = async (): Promise<StrategyCompound> => {
    const [admin] = await hre.ethers.getSigners();
    const strategyCompoundContract = await hre.ethers.getContractFactory("StrategyCompound", admin);
    return (await upgrades.deployProxy(
        strategyCompoundContract,
        [daiAddress, cDaiAddress, comptrollerAddress, compTokenAddress],
        {
            kind: "uups",
        }
    )) as Promise<StrategyCompound>;
};

export const compoundUsdcStrategyFactory = async (): Promise<StrategyCompound> => {
    const [admin] = await hre.ethers.getSigners();
    const strategyCompoundContract = await hre.ethers.getContractFactory("StrategyCompound", admin);
    return (await upgrades.deployProxy(
        strategyCompoundContract,
        [usdcAddress, cUsdcAddress, comptrollerAddress, compTokenAddress],
        {
            kind: "uups",
        }
    )) as Promise<StrategyCompound>;
};

export const compoundUsdtStrategyFactory = async (): Promise<StrategyCompound> => {
    const [admin] = await hre.ethers.getSigners();
    const strategyCompoundContract = await hre.ethers.getContractFactory("StrategyCompound", admin);
    return (await upgrades.deployProxy(
        strategyCompoundContract,
        [usdtAddress, cUsdtAddress, comptrollerAddress, compTokenAddress],
        {
            kind: "uups",
        }
    )) as Promise<StrategyCompound>;
};

export const strategyCompoundSetup = async (strategy: StrategyCompound, stanleyAddress: string) => {
    await strategy.setStanley(stanleyAddress);
};
