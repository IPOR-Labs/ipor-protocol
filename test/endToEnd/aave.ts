import hre from "hardhat";

import { ERC20, AaveStrategy } from "../../types";
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

export const aaveDaiStrategyFactory = async (): Promise<AaveStrategy> => {
    const [admin] = await hre.ethers.getSigners();
    const aaveStrategyContract = await hre.ethers.getContractFactory("AaveStrategy", admin);
    return (await upgrades.deployProxy(
        aaveStrategyContract,
        [daiAddress, aDaiAddress, addressProvider, stkAave, aaveIncentiveAddress, aaveAaddress],
        {
            kind: "uups",
        }
    )) as Promise<AaveStrategy>;
};

export const aaveUsdcStrategyFactory = async (): Promise<AaveStrategy> => {
    const [admin] = await hre.ethers.getSigners();
    const aaveStrategyContract = await hre.ethers.getContractFactory("AaveStrategy", admin);
    return (await upgrades.deployProxy(
        aaveStrategyContract,
        [usdcAddress, aUsdcAddress, addressProvider, stkAave, aaveIncentiveAddress, aaveAaddress],
        {
            kind: "uups",
        }
    )) as Promise<AaveStrategy>;
};

export const aaveUsdtStrategyFactory = async (): Promise<AaveStrategy> => {
    const [admin] = await hre.ethers.getSigners();
    const aaveStrategyContract = await hre.ethers.getContractFactory("AaveStrategy", admin);
    return (await upgrades.deployProxy(
        aaveStrategyContract,
        [usdtAddress, aUsdtAddress, addressProvider, stkAave, aaveIncentiveAddress, aaveAaddress],
        {
            kind: "uups",
        }
    )) as Promise<AaveStrategy>;
};

export const aaveStrategySetup = async (strategy: AaveStrategy, stanleyAddress: string) => {
    await strategy.setStanley(stanleyAddress);
};
