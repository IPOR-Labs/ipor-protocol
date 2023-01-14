import hre, { upgrades } from "hardhat";
import { BigNumber, Signer } from "ethers";

import { ItfIporOracle, MockIporWeighted } from "../../types";

const { ethers } = hre;

// ########################################################################################################
//                                           IporOracle
// ########################################################################################################

export const prepareIporOracle = async (
    accounts: Signer[],
    assets: string[],
    lastUpdateTimestamps: BigNumber[],
    exponentialMovingAverages: BigNumber[],
    exponentialWeightedMovingVariances: BigNumber[]
): Promise<ItfIporOracle> => {
    const ItfIporOracle = await ethers.getContractFactory("ItfIporOracle");

    const iporOracle = (await upgrades.deployProxy(
        ItfIporOracle,
        [
            assets,
            lastUpdateTimestamps,
            exponentialMovingAverages,
            exponentialWeightedMovingVariances,
        ],
        {
            kind: "uups",
        }
    )) as ItfIporOracle;

    const MockIporWeighted = await ethers.getContractFactory("MockIporWeighted");

    const mockIporWeighted = (await upgrades.deployProxy(MockIporWeighted, [iporOracle.address], {
        kind: "uups",
    })) as MockIporWeighted;

    await iporOracle.setIporAlgorithmFacade(mockIporWeighted.address);

    if (accounts[1]) {
        await iporOracle.addUpdater(await accounts[1].getAddress());
    }
    return iporOracle;
};
