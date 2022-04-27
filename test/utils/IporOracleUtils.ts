import hre from "hardhat";
import { BigNumber, Signer } from "ethers";

import { ItfIporOracle } from "../../types";

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
    const iporOracle = (await ItfIporOracle.deploy()) as ItfIporOracle;
	
    await iporOracle.initialize(
        assets,
        lastUpdateTimestamps,
        exponentialMovingAverages,
        exponentialWeightedMovingVariances
    );
    if (accounts[1]) {
        await iporOracle.addUpdater(await accounts[1].getAddress());
    }
    return iporOracle;
};
