import hre from "hardhat";

import { ERC20, StrategyAave } from "../../types";
import {
    daiAddress,
    aDaiAddress,
    usdcAddress,
    aUsdcAddress,
    usdtAddress,
    aUsdtAddress,
} from "./tokens";

const addressProvider = "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5";

const usdcAbi = require("../../abis/usdcAbi.json");
const usdtAbi = require("../../abis/usdtAbi.json");
const daiAbi = require("../../abis/daiAbi.json");

const aaveAaddress = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
const stkAave = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";
const aaveIncentiveAddress = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";

export const aaveTokenFactory = async (): Promise<ERC20> => {
    const [admin] = await hre.ethers.getSigners();
    return new hre.ethers.Contract(aaveAaddress, daiAbi, admin) as ERC20;
};

export const aaveDaiStrategyFactory = async (): Promise<StrategyAave> => {
    const [admin] = await hre.ethers.getSigners();
    const strategyAaveContract = await hre.ethers.getContractFactory("StrategyAave", admin);
    return (await upgrades.deployProxy(
        strategyAaveContract,
        [daiAddress, aDaiAddress, addressProvider, stkAave, aaveIncentiveAddress, aaveAaddress],
        {
            kind: "uups",
        }
    )) as Promise<StrategyAave>;
};

export const aaveUsdcStrategyFactory = async (): Promise<StrategyAave> => {
    const [admin] = await hre.ethers.getSigners();
    const strategyAaveContract = await hre.ethers.getContractFactory("StrategyAave", admin);
    return (await upgrades.deployProxy(
        strategyAaveContract,
        [usdcAddress, aUsdcAddress, addressProvider, stkAave, aaveIncentiveAddress, aaveAaddress],
        {
            kind: "uups",
        }
    )) as Promise<StrategyAave>;
};

export const aaveUsdtStrategyFactory = async (): Promise<StrategyAave> => {
    const [admin] = await hre.ethers.getSigners();
    const strategyAaveContract = await hre.ethers.getContractFactory("StrategyAave", admin);
    return (await upgrades.deployProxy(
        strategyAaveContract,
        [usdtAddress, aUsdtAddress, addressProvider, stkAave, aaveIncentiveAddress, aaveAaddress],
        {
            kind: "uups",
        }
    )) as Promise<StrategyAave>;
};

export const strategyAaveSetup = async (strategy: StrategyAave, stanleyAddress: string) => {
    await strategy.setStanley(stanleyAddress);
};
