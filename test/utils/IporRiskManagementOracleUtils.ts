import hre, { upgrades } from "hardhat";
import {BigNumber, Signer} from "ethers";

import { IporRiskManagementOracle } from "../../types";

const { ethers } = hre;

// ########################################################################################################
//                                           IporRiskManagementOracle
// ########################################################################################################

export const prepareRiskManagementOracle = async (
    accounts: Signer[],
    assets: string[],
    maxNotionalPayFixed: BigNumber[],
    maxNotionalReceiveFixed: BigNumber[],
    maxUtilizationRatePayFixed: BigNumber[],
    maxUtilizationRateReceiveFixed: BigNumber[],
    maxUtilizationRate: BigNumber[],
): Promise<IporRiskManagementOracle> => {
    const iporRiskManagementOracle = await ethers.getContractFactory("IporRiskManagementOracle");

    const iporRiskManagementOracleProxy = (await upgrades.deployProxy(
        iporRiskManagementOracle,
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
    )) as IporRiskManagementOracle;

    for (let i = 0; i < accounts.length; i++) {
        await iporRiskManagementOracleProxy.addUpdater(await accounts[i].getAddress());
    }
    return iporRiskManagementOracleProxy;
};
