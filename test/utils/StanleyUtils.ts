import hre from "hardhat";

import { MockCase0Stanley, MockCase1Stanley, MockCase2Stanley } from "../../types";

const { ethers } = hre;

// ########################################################################################################
//                                           Stanley
// ########################################################################################################

export enum MockStanleyCase {
    CASE0 = "MockCase0Stanley",
    CASE1 = "MockCase1Stanley",
    CASE2 = "MockCase2Stanley",
}

export type MockStanley = MockCase0Stanley | MockCase1Stanley | MockCase2Stanley;

export const getMockStanleyCase = async (
    stanleyCase: MockStanleyCase,
    assetAddress: string
): Promise<MockStanley> => {
    let MockCaseStanley = await ethers.getContractFactory(stanleyCase);
    const mockCaseStanley = (await MockCaseStanley.deploy(assetAddress)) as MockStanley;
    return mockCaseStanley;
};
