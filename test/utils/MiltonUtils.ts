import { Signer, BigNumber } from "ethers";
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
    UsdtMockedToken,
} from "../../types";

import { USD_10_000_6DEC, LEVERAGE_18DEC, N0__01_18DEC } from "./Constants";

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
    console.log(miltonCase);
    const MockCaseMilton = await ethers.getContractFactory(miltonCase);
    return (await MockCaseMilton.deploy()) as MiltonDaiMockCase;
};

export const prepareMiltonSpreadCase2 = async () => {
    const MockCase2MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase2MiltonSpreadModel"
    );
    const miltonSpread = await MockCase2MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const prepareMiltonSpreadCase3 = async () => {
    const MockCase3MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase3MiltonSpreadModel"
    );
    const miltonSpread = await MockCase3MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const prepareMiltonSpreadCase4 = async () => {
    const MockCase4MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase4MiltonSpreadModel"
    );
    const miltonSpread = await MockCase4MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const prepareMiltonSpreadCase5 = async () => {
    const MockCase5MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase5MiltonSpreadModel"
    );
    const miltonSpread = await MockCase5MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const prepareMiltonSpreadCase6 = async () => {
    const MockCase6MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase6MiltonSpreadModel"
    );
    const miltonSpread = await MockCase6MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const prepareMiltonSpreadCase8 = async () => {
    const MockCase8MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase8MiltonSpreadModel"
    );
    const miltonSpread = await MockCase8MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const prepareMiltonSpreadCase9 = async () => {
    const MockCase9MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase9MiltonSpreadModel"
    );
    const miltonSpread = await MockCase9MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const prepareMiltonSpreadCase10 = async () => {
    const MockCase10MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase10MiltonSpreadModel"
    );
    const miltonSpread = await MockCase10MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const prepareMiltonSpreadCase11 = async () => {
    const MockCase11MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase11MiltonSpreadModel"
    );
    const miltonSpread = await MockCase11MiltonSpreadModel.deploy();
    await miltonSpread.initialize();
    return miltonSpread;
};

export const getPayFixedDerivativeParamsUSDTCase1 = (user: Signer, tokenUsdt: UsdtMockedToken) => {
    return {
        asset: tokenUsdt.address,
        totalAmount: USD_10_000_6DEC,
        toleratedQuoteValue: BigNumber.from("6").mul(N0__01_18DEC),
        leverage: LEVERAGE_18DEC,
        direction: 0,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: user,
    };
};
