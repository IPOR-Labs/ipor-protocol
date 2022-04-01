import hre from "hardhat";
import { Signer } from "ethers";

import { ItfIporOracle } from "../../types";

const { ethers } = hre;

// ########################################################################################################
//                                           IporOracle
// ########################################################################################################

export const prepareIporOracle = async (accounts: Signer[]): Promise<ItfIporOracle> => {
    const ItfIporOracle = await ethers.getContractFactory("ItfIporOracle");
    const iporOracle = (await ItfIporOracle.deploy()) as ItfIporOracle;
    await iporOracle.initialize();
    if (accounts[1]) {
        await iporOracle.addUpdater(await accounts[1].getAddress());
    }
    return iporOracle;
};
