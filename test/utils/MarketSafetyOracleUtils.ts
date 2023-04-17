import hre, { upgrades } from "hardhat";
import {BigNumber, Signer} from "ethers";

import { MarketSafetyOracle } from "../../types";

const { ethers } = hre;

// ########################################################################################################
//                                           MarketSafetyOracle
// ########################################################################################################

export const prepareMarketSafetyOracle = async (
    accounts: Signer[],
    assets: string[],
    maxNotionalPayFixed: BigNumber[],
    maxNotionalReceiveFixed: BigNumber[],
    maxUtilizationRatePayFixed: BigNumber[],
    maxUtilizationRateReceiveFixed: BigNumber[],
    maxUtilizationRate: BigNumber[],
): Promise<MarketSafetyOracle> => {
    const marketSafetyOracle = await ethers.getContractFactory("MarketSafetyOracle");

    const marketSafetyOracleProxy = (await upgrades.deployProxy(
        marketSafetyOracle,
        [
            assets,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            maxUtilizationRate,
        ],
        {
            kind: "uups",
        }
    )) as MarketSafetyOracle;

    for (let i = 0; i < accounts.length; i++) {
        await marketSafetyOracleProxy.addUpdater(await accounts[i].getAddress());
    }
    return marketSafetyOracleProxy;
};
