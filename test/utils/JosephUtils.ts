import hre from "hardhat";
import {
    MockCase0JosephUsdt,
    MockCase1JosephUsdt,
    MockCase0JosephUsdc,
    MockCase1JosephUsdc,
    MockCase0JosephDai,
    MockCase1JosephDai,
} from "../../types";

const { ethers } = hre;

// ########################################################################################################
//                                           Joseph
// ########################################################################################################

export enum JosephUsdcMockCases {
    CASE0 = "MockCase0JosephUsdc",
    CASE1 = "MockCase1JosephUsdc",
}

export enum JosephUsdtMockCases {
    CASE0 = "MockCase0JosephUsdt",
    CASE1 = "MockCase1JosephUsdt",
}

export enum JosephDaiMockCases {
    CASE0 = "MockCase0JosephDai",
    CASE1 = "MockCase1JosephDai",
}

export type JosephUsdcMocks = MockCase0JosephUsdc | MockCase1JosephUsdc;

export type JosephUsdtMocks = MockCase0JosephUsdt | MockCase1JosephUsdt;

export type JosephDaiMocks = MockCase0JosephDai | MockCase1JosephDai;

export const getMockJosephUsdtCase = async (
    josephCase: JosephUsdtMockCases
): Promise<JosephUsdtMocks> => {
    const MockCaseJoseph = await ethers.getContractFactory(josephCase);
    const mockCaseJoseph = (await MockCaseJoseph.deploy()) as JosephUsdtMocks;
    return mockCaseJoseph;
};

export const getMockJosephUsdcCase = async (
    josephCaseNumber: JosephUsdcMockCases
): Promise<JosephUsdcMocks> => {
    let MockCaseJoseph = await ethers.getContractFactory(josephCaseNumber);
    return (await MockCaseJoseph.deploy()) as JosephUsdcMocks;
};

export const getMockJosephDaiCase = async (
    josephCase: JosephDaiMockCases
): Promise<JosephDaiMocks> => {
    let MockCaseJoseph = await ethers.getContractFactory(josephCase);
    return (await MockCaseJoseph.deploy()) as JosephDaiMocks;
};
