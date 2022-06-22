import { Signer, BigNumber } from "ethers";
import hre from "hardhat";

import {
    MockBaseMiltonSpreadModel,
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
    MockCase8MiltonDai,
    UsdtMockedToken,
    MockSpreadModel,
} from "../../types";

import { executeCloseSwapTestCase } from "./SwapUtils";

import {
    USD_10_000_6DEC,
    LEVERAGE_18DEC,
    N0__01_18DEC,
    ZERO,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_OPENING_FEE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    USER_SUPPLY_10MLN_18DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_6DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC,
    TC_IPOR_PUBLICATION_AMOUNT_6DEC,
    TC_OPENING_FEE_6DEC,
    USER_SUPPLY_6_DECIMALS,
} from "./Constants";
import { TestData } from "./DataUtils";

const { ethers } = hre;

// ########################################################################################################
//                                           Milton
// ########################################################################################################

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
    CASE7 = "MockCase7MiltonDai",
    CASE8 = "MockCase8MiltonDai",
}

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
    | MockCase6MiltonDai
    | MockCase8MiltonDai;

export const prepareMockMiltonSpreadModel = async (): Promise<MockBaseMiltonSpreadModel> => {
    const MockMiltonSpreadModel = await ethers.getContractFactory("MockBaseMiltonSpreadModel");
    const miltonSpread = (await MockMiltonSpreadModel.deploy()) as MockBaseMiltonSpreadModel;
    return miltonSpread;
};

export const prepareMockSpreadModel = async (
    calculateQuotePayFixedValue: BigNumber,
    calculateQuoteReceiveFixedValue: BigNumber,
    calculateSpreadPayFixedValue: BigNumber,
    calculateSpreadReceiveFixedVaule: BigNumber
): Promise<MockSpreadModel> => {
    const MockSpreadModel = await ethers.getContractFactory("MockSpreadModel");
    const miltonSpread = (await MockSpreadModel.deploy(
        calculateQuotePayFixedValue,
        calculateQuoteReceiveFixedValue,
        calculateSpreadPayFixedValue,
        calculateSpreadReceiveFixedVaule
    )) as MockSpreadModel;
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

export const getPayFixedDerivativeParamsUSDTCase1 = (user: Signer, tokenUsdt: UsdtMockedToken) => {
    return {
        asset: tokenUsdt.address,
        totalAmount: USD_10_000_6DEC,
        acceptableFixedInterestRate: BigNumber.from("6").mul(N0__01_18DEC),
        leverage: LEVERAGE_18DEC,
        direction: 0,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: user,
    };
};

export const getReceiveFixedDerivativeParamsUSDTCase1 = (
    user: Signer,
    tokenUsdt: UsdtMockedToken
) => {
    return {
        asset: tokenUsdt.address,
        totalAmount: USD_10_000_6DEC,
        acceptableFixedInterestRate: N0__01_18DEC,
        leverage: LEVERAGE_18DEC,
        direction: 0,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: user,
    };
};

export const prepareMiltonSpreadBase = async () => {
    const MockBaseMiltonSpreadModel = await ethers.getContractFactory("MockBaseMiltonSpreadModel");
    const miltonSpread = await MockBaseMiltonSpreadModel.deploy();
    return miltonSpread;
};

export const testCaseWhenMiltonEarnAndUserLost = async function (
    testData: TestData,
    asset: string,
    leverage: BigNumber,
    direction: BigNumber,
    openerUser: Signer,
    closerUser: Signer,
    iporValueAfterOpenSwap: BigNumber,
    acceptableFixedInterestRate: BigNumber,
    periodOfTimeElapsedInSeconds: BigNumber,
    expectedOpenedPositions: BigNumber,
    expectedDerivativesTotalBalanceWad: BigNumber,
    expectedTreasuryTotalBalanceWad: BigNumber,
    expectedSoap: BigNumber,
    openTimestamp: BigNumber,
    expectedIncomeFeeValueWad: BigNumber,
    expectedPayoff: BigNumber,
    expectedPayoffWad: BigNumber,
    userOne: Signer,
    liquidityProvider: Signer
) {
    let expectedPayoffWadAbs = expectedPayoffWad;
    let expectedPayoffAbs = expectedPayoff;

    if (expectedPayoffWad.lt(ZERO)) {
        expectedPayoffWadAbs = BigNumber.from(expectedPayoffWadAbs).mul("-1");
        expectedPayoffAbs = BigNumber.from(expectedPayoffAbs).mul("-1");
    }

    let miltonBalanceBeforePayout = ZERO;
    let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
    let openerUserLost = null;
    let openerUserEarned = null;
    let closerUserLost = null;
    let closerUserEarned = null;
    let expectedOpenerUserUnderlyingTokenBalanceAfterClose = ZERO;
    let expectedCloserUserUnderlyingTokenBalanceAfterClose = ZERO;
    let expectedMiltonUnderlyingTokenBalance = ZERO;
    let expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad
        .add(TC_OPENING_FEE_18DEC)
        .add(expectedPayoffWadAbs)
        .sub(expectedIncomeFeeValueWad);

    if (testData.tokenDai && asset === testData.tokenDai.address) {
        miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        openerUserLost = TC_OPENING_FEE_18DEC.add(TC_IPOR_PUBLICATION_AMOUNT_18DEC)
            .add(TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC)
            .add(expectedPayoffAbs);

        if ((await openerUser.getAddress()) === (await closerUser.getAddress())) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC.add(openerUserEarned).sub(openerUserLost);
        expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC.add(closerUserEarned).sub(closerUserLost);
        expectedMiltonUnderlyingTokenBalance = TC_LP_BALANCE_BEFORE_CLOSE_18DEC.add(
            TC_OPENING_FEE_18DEC
        )
            .add(TC_IPOR_PUBLICATION_AMOUNT_18DEC)
            .add(expectedPayoffAbs);
    }

    if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
        closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
        openerUserLost = TC_OPENING_FEE_6DEC.add(TC_IPOR_PUBLICATION_AMOUNT_6DEC)
            .add(TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC)
            .add(expectedPayoffAbs);

        if ((await openerUser.getAddress()) === (await closerUser.getAddress())) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_6_DECIMALS.add(openerUserEarned).sub(openerUserLost);
        expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_6_DECIMALS.add(closerUserEarned).sub(closerUserLost);

        expectedMiltonUnderlyingTokenBalance = TC_LP_BALANCE_BEFORE_CLOSE_6DEC.add(
            TC_OPENING_FEE_6DEC
        )
            .add(TC_IPOR_PUBLICATION_AMOUNT_6DEC)
            .add(expectedPayoffAbs);
    }

    await executeCloseSwapTestCase(
        testData,
        asset,
        leverage,
        direction,
        openerUser,
        closerUser,        
        iporValueAfterOpenSwap,
        acceptableFixedInterestRate,
        periodOfTimeElapsedInSeconds,
        miltonBalanceBeforePayout,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserUnderlyingTokenBalanceAfterClose,
        expectedCloserUserUnderlyingTokenBalanceAfterClose,
        expectedLiquidityPoolTotalBalanceWad,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        expectedPayoffWad,
        expectedIncomeFeeValueWad,
        userOne,
        liquidityProvider
    );
};

export const testCaseWhenMiltonLostAndUserEarn = async function (
    testData: TestData,
    asset: string,
    leverage: BigNumber,
    direction: BigNumber,
    openerUser: Signer,
    closerUser: Signer,
    iporValueAfterOpenSwap: BigNumber,
    acceptableFixedInterestRate: BigNumber,
    periodOfTimeElapsedInSeconds: BigNumber,
    expectedOpenedPositions: BigNumber,
    expectedDerivativesTotalBalanceWad: BigNumber,
    expectedTreasuryTotalBalanceWad: BigNumber,
    expectedSoap: BigNumber,
    openTimestamp: BigNumber,
    expectedIncomeFeeValue: BigNumber,
    expectedIncomeFeeValueWad: BigNumber,
    expectedPayoff: BigNumber,
    expectedPayoffWad: BigNumber,
    userOne: Signer,
    liquidityProvider: Signer
) {
    let expectedPayoffWadAbs = expectedPayoffWad;
    let expectedPayoffAbs = expectedPayoff;

    if (expectedPayoffWad.lt(ZERO)) {
        expectedPayoffWadAbs = expectedPayoffWadAbs.mul("-1");
        expectedPayoffAbs = expectedPayoffAbs.mul("-1");
    }

    let miltonBalanceBeforePayout = ZERO;
    let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
    let closerUserEarned = null;
    let openerUserLost = null;
    let closerUserLost = null;
    let openerUserEarned = null;
    let expectedMiltonUnderlyingTokenBalance = ZERO;
    let expectedOpenerUserUnderlyingTokenBalanceAfterClose = ZERO;
    let expectedCloserUserUnderlyingTokenBalanceAfterClose = ZERO;

    let expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad
        .sub(expectedPayoffWadAbs)
        .add(TC_OPENING_FEE_18DEC);

    if (testData.tokenDai && asset === testData.tokenDai.address) {
        miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        openerUserLost = TC_OPENING_FEE_18DEC.add(TC_IPOR_PUBLICATION_AMOUNT_18DEC)
            .add(TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC)
            .sub(expectedPayoffAbs)
            .add(expectedIncomeFeeValue);

        if ((await openerUser.getAddress()) === (await closerUser.getAddress())) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        expectedMiltonUnderlyingTokenBalance = TC_LP_BALANCE_BEFORE_CLOSE_18DEC.add(
            TC_OPENING_FEE_18DEC
        )
            .add(TC_IPOR_PUBLICATION_AMOUNT_18DEC)
            .sub(expectedPayoffAbs)
            .add(expectedIncomeFeeValue);
        expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC.add(openerUserEarned).sub(openerUserLost);
        expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC.add(closerUserEarned).sub(closerUserLost);
    }

    if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
        closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
        openerUserLost = TC_OPENING_FEE_6DEC.add(TC_IPOR_PUBLICATION_AMOUNT_6DEC)
            .add(TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC)
            .sub(expectedPayoffAbs)
            .add(expectedIncomeFeeValue);

        if ((await openerUser.getAddress()) === (await closerUser.getAddress())) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        expectedMiltonUnderlyingTokenBalance = TC_LP_BALANCE_BEFORE_CLOSE_6DEC.add(
            TC_OPENING_FEE_6DEC
        )
            .add(TC_IPOR_PUBLICATION_AMOUNT_6DEC)
            .sub(expectedPayoffAbs)
            .add(expectedIncomeFeeValue);
        expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_6_DECIMALS.add(openerUserEarned).sub(openerUserLost);
        expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_6_DECIMALS.add(closerUserEarned).sub(closerUserLost);
    }
    expectedPayoff = expectedPayoffWad;
    await executeCloseSwapTestCase(
        testData,
        asset,
        leverage,
        direction,
        openerUser,
        closerUser,
        iporValueAfterOpenSwap,
        acceptableFixedInterestRate,
        periodOfTimeElapsedInSeconds,
        miltonBalanceBeforePayout,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserUnderlyingTokenBalanceAfterClose,
        expectedCloserUserUnderlyingTokenBalanceAfterClose,
        expectedLiquidityPoolTotalBalanceWad,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        expectedPayoffWad,
        expectedIncomeFeeValueWad,
        userOne,
        liquidityProvider
    );
};
