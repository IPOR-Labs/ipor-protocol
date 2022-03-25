import hre from "hardhat";
import { Signer } from "ethers";

import { ItfWarren } from "../../types";

const { ethers } = hre;

// ########################################################################################################
//                                           Warren
// ########################################################################################################

export const prepareWarren = async (accounts: Signer[]): Promise<ItfWarren> => {
    const ItfWarren = await ethers.getContractFactory("ItfWarren");
    const warren = (await ItfWarren.deploy()) as ItfWarren;
    await warren.initialize();
    if (accounts[1]) {
        await warren.addUpdater(await accounts[1].getAddress());
    }
    return warren;
};
