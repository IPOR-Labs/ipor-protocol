import hre from "hardhat";

import {
    MockBaseMiltonSpreadModel,
    MockCase1MiltonSpreadModel,
    MockCase2MiltonSpreadModel,
    MockCase3MiltonSpreadModel,
    MockCase4MiltonSpreadModel,
    MockCase5MiltonSpreadModel,
    MockCase6MiltonSpreadModel,
    MockCase7MiltonSpreadModel,
    MockCase8MiltonSpreadModel,
    MockCase9MiltonSpreadModel,
    MockCase10MiltonSpreadModel,
    MockCase11MiltonSpreadModel,
    MockCase0MiltonUsdt,
    MockCase1MiltonUsdt,
    MockCase2MiltonUsdt,
    MockCase3MiltonUsdt,
    MockCase4MiltonUsdt,
    MockCase5MiltonUsdt,
    MockCase6MiltonUsdt,
    MockCase0MiltonUsdc,
    MockCase1MiltonUsdc,
    MockCase2MiltonUsdc,
    MockCase3MiltonUsdc,
    MockCase4MiltonUsdc,
    MockCase5MiltonUsdc,
    MockCase6MiltonUsdc,
    MockCase0MiltonDai,
    MockCase1MiltonDai,
    MockCase2MiltonDai,
    MockCase3MiltonDai,
    MockCase4MiltonDai,
    MockCase5MiltonDai,
    MockCase6MiltonDai,
} from "../../types";

const { ethers } = hre;

// ########################################################################################################
//                                           Milton
// ########################################################################################################

export enum MiltonSpreadModels {
    BASE = "MockBaseMiltonSpreadModel",
    CASE1 = "MockCase1MiltonSpreadModel",
    CASE2 = "MockCase2MiltonSpreadModel",
    CASE3 = "MockCase3MiltonSpreadModel",
    CASE4 = "MockCase4MiltonSpreadModel",
    CASE5 = "MockCase5MiltonSpreadModel",
    CASE6 = "MockCase6MiltonSpreadModel",
    CASE7 = "MockCase7MiltonSpreadModel",
    CASE8 = "MockCase8MiltonSpreadModel",
    CASE9 = "MockCase9MiltonSpreadModel",
    CASE10 = "MockCase10MiltonSpreadModel",
    CASE11 = "MockCase11MiltonSpreadModel",
}

export enum MiltonUsdcCase {
    CASE0 = "MockCase0MiltonUsdc",
    CASE1 = "MockCase1MiltonUsdc",
    CASE2 = "MockCase2MiltonUsdc",
    CASE3 = "MockCase3MiltonUsdc",
    CASE4 = "MockCase4MiltonUsdc",
    CASE5 = "MockCase5MiltonUsdc",
    CASE6 = "MockCase6MiltonUsdc",
}

export enum MiltonUsdtCase {
    CASE0 = "MockCase0MiltonUsdt",
    CASE1 = "MockCase1MiltonUsdt",
    CASE2 = "MockCase2MiltonUsdt",
    CASE3 = "MockCase3MiltonUsdt",
    CASE4 = "MockCase4MiltonUsdt",
    CASE5 = "MockCase5MiltonUsdt",
    CASE6 = "MockCase6MiltonUsdt",
}

export enum MiltonDaiCase {
    CASE0 = "MockCase0MiltonDai",
    CASE1 = "MockCase1MiltonDai",
    CASE2 = "MockCase2MiltonDai",
    CASE3 = "MockCase3MiltonDai",
    CASE4 = "MockCase4MiltonDai",
    CASE5 = "MockCase5MiltonDai",
    CASE6 = "MockCase6MiltonDai",
}

export type MockMiltonSpreadModel =
    | MockBaseMiltonSpreadModel
    | MockCase1MiltonSpreadModel
    | MockCase2MiltonSpreadModel
    | MockCase3MiltonSpreadModel
    | MockCase4MiltonSpreadModel
    | MockCase5MiltonSpreadModel
    | MockCase6MiltonSpreadModel
    | MockCase7MiltonSpreadModel
    | MockCase8MiltonSpreadModel
    | MockCase9MiltonSpreadModel
    | MockCase10MiltonSpreadModel
    | MockCase11MiltonSpreadModel;

export type MiltonUsdcMockCase =
    | MockCase0MiltonUsdc
    | MockCase1MiltonUsdc
    | MockCase2MiltonUsdc
    | MockCase3MiltonUsdc
    | MockCase4MiltonUsdc
    | MockCase5MiltonUsdc
    | MockCase6MiltonUsdc;

export type MiltonUsdtMockCase =
    | MockCase0MiltonUsdt
    | MockCase1MiltonUsdt
    | MockCase2MiltonUsdt
    | MockCase3MiltonUsdt
    | MockCase4MiltonUsdt
    | MockCase5MiltonUsdt
    | MockCase6MiltonUsdt;

export type MiltonDaiMockCase =
    | MockCase0MiltonDai
    | MockCase1MiltonDai
    | MockCase2MiltonDai
    | MockCase3MiltonDai
    | MockCase4MiltonDai
    | MockCase5MiltonDai
    | MockCase6MiltonDai;

export const prepareMockMiltonSpreadModel = async (
    spreadmiltonCase: MiltonSpreadModels
): Promise<MockMiltonSpreadModel> => {
    const MockMiltonSpreadModel = await ethers.getContractFactory(spreadmiltonCase);
    const miltonSpread = (await MockMiltonSpreadModel.deploy()) as MockMiltonSpreadModel;
    await miltonSpread.initialize();
    return miltonSpread;
};

export const getMockMiltonUsdtCase = async (
    miltonCase: MiltonUsdtCase
): Promise<MiltonUsdtMockCase> => {
    let MockCaseMilton = await ethers.getContractFactory(miltonCase);
    const mockCaseMilton = (await MockCaseMilton.deploy()) as MiltonUsdtMockCase;
    return mockCaseMilton;
};

export const getMockMiltonUsdcCase = async (
    miltonCase: MiltonUsdcCase
): Promise<MiltonUsdcMockCase> => {
    const MockCaseMilton = await ethers.getContractFactory(miltonCase);
    return (await MockCaseMilton.deploy()) as MiltonUsdcMockCase;
};

export const getMockMiltonDaiCase = async (
    miltonCase: MiltonDaiCase
): Promise<MiltonDaiMockCase> => {
    const MockCaseMilton = await ethers.getContractFactory(miltonCase);
    return (await MockCaseMilton.deploy()) as MiltonDaiMockCase;
};
