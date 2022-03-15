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

import { ERC20, CompoundStrategy } from "../../types";

const comptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";
const compTokenAddress = "0xc00e94Cb662C3520282E6f5717214004A7f26888";

export const compTokenFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(compTokenAddress, daiComp, admin) as ERC20;
};

export const compoundDaiStrategyFactory = async (): Promise<CompoundStrategy> => {
    const [admin] = await hre.ethers.getSigners();
    const compoundStrategyContract = await hre.ethers.getContractFactory("CompoundStrategy", admin);
    return (await upgrades.deployProxy(
        compoundStrategyContract,
        [daiAddress, cDaiAddress, comptrollerAddress, compTokenAddress],
        {
            kind: "uups",
        }
    )) as Promise<CompoundStrategy>;
};

export const compoundUsdcStrategyFactory = async (): Promise<CompoundStrategy> => {
    const [admin] = await hre.ethers.getSigners();
    const compoundStrategyContract = await hre.ethers.getContractFactory("CompoundStrategy", admin);
    return (await upgrades.deployProxy(
        compoundStrategyContract,
        [usdcAddress, cUsdcAddress, comptrollerAddress, compTokenAddress],
        {
            kind: "uups",
        }
    )) as Promise<CompoundStrategy>;
};

export const compoundUsdtStrategyFactory = async (): Promise<CompoundStrategy> => {
    const [admin] = await hre.ethers.getSigners();
    const compoundStrategyContract = await hre.ethers.getContractFactory("CompoundStrategy", admin);
    return (await upgrades.deployProxy(
        compoundStrategyContract,
        [usdtAddress, cUsdtAddress, comptrollerAddress, compTokenAddress],
        {
            kind: "uups",
        }
    )) as Promise<CompoundStrategy>;
};

export const compoundStrategySetup = async (strategy: CompoundStrategy, stanleyAddress: string) => {
    await strategy.setStanley(stanleyAddress);
};
