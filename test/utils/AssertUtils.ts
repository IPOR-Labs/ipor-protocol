import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    TestData,
} from "./DataUtils";
import {
    MockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "./MiltonUtils";

import { Derivatives, countOpenSwaps } from "./SwapUtils";

import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "./JosephUtils";
import { MockStanleyCase } from "./StanleyUtils";
import { openSwapPayFixed, openSwapReceiveFixed } from "./SwapUtils";

import {
    N0__1_18DEC,
    N0__01_18DEC,
    TC_TOTAL_AMOUNT_100_18DEC,
    LEVERAGE_18DEC,
    PERCENTAGE_5_18DEC,
    USD_50_000_18DEC,
    USD_10_18DEC,
    USD_10_000_000_18DEC,
    USD_10_000_000_6DEC,
    ZERO,
} from "./Constants";

const { expect } = chai;

type ErrorWithMessage = {
    message: string;
};

const isErrorWithMessage = (error: unknown): error is ErrorWithMessage => {
    return (
        typeof error === "object" &&
        error !== null &&
        "message" in error &&
        typeof (error as Record<string, unknown>).message === "string"
    );
};

const toErrorWithMessage = (maybeError: unknown): ErrorWithMessage => {
    if (isErrorWithMessage(maybeError)) return maybeError;

    try {
        return new Error(JSON.stringify(maybeError));
    } catch {
        // fallback in case there's an error stringifying the maybeError
        // like with circular references for example.
        return new Error(String(maybeError));
    }
};

export const assertError = async (promise: Promise<any>, error: string) => {
    try {
        await promise;
    } catch (e: unknown) {
        const errorResult = toErrorWithMessage(e);
        expect(
            errorResult.message.includes(error),
            `Expected exception with message ${error} but actual error message: ${errorResult.message}`
        ).to.be.true;
        return;
    }
    expect(false).to.be.true;
};
export const testCasePagination = async (
    users: Signer[],
    numberOfSwapsToCreate: BigNumber,
    offset: BigNumber,
    pageSize: BigNumber,
    expectedResponseSize: BigNumber,
    expectedError: string | null,
    miltonSpreadModel: MockMiltonSpreadModel | MockSpreadModel
) => {
    //given
    const testData = await prepareTestData(
        BigNumber.from(Math.floor(Date.now() / 1000)),
        users,
        ["DAI", "USDC", "USDT"],
        [],
        miltonSpreadModel,
        MiltonUsdcCase.CASE0,
        MiltonUsdtCase.CASE0,
        MiltonDaiCase.CASE0,
        MockStanleyCase.CASE1,
        JosephUsdcMockCases.CASE0,
        JosephUsdtMockCases.CASE0,
        JosephDaiMockCases.CASE0
    );
    const [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] = users;

    await prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", testData);
    await setupTokenDaiInitialValuesForUsers(
        [admin, userOne, userTwo, liquidityProvider],
        testData
    );

    const {
        miltonDai,
        tokenDai,
        josephDai,
        iporOracle,
        tokenUsdt,
        tokenUsdc,
        miltonUsdt,
        miltonUsdc,
        miltonStorageDai,
        miltonStorageUsdc,
        miltonStorageUsdt,
        josephUsdt,
        josephUsdc,
    } = testData;

    if (
        miltonDai === undefined ||
        tokenDai === undefined ||
        josephDai === undefined ||
        tokenUsdt === undefined ||
        tokenUsdc === undefined ||
        miltonUsdt === undefined ||
        miltonUsdc === undefined ||
        miltonStorageDai === undefined ||
        miltonStorageUsdc === undefined ||
        miltonStorageUsdt === undefined ||
        josephUsdt === undefined ||
        josephUsdc === undefined
    ) {
        expect(true).to.be.false;
        return;
    }

    const paramsDai = {
        asset: tokenDai.address,
        totalAmount: TC_TOTAL_AMOUNT_100_18DEC,
        leverage: LEVERAGE_18DEC,
        acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: userTwo,
    };

    await iporOracle
        .connect(userOne)
        .itfUpdateIndex(paramsDai.asset, PERCENTAGE_5_18DEC, paramsDai.openTimestamp);

    await josephDai
        .connect(liquidityProvider)
        .itfProvideLiquidity(USD_50_000_18DEC, paramsDai.openTimestamp);

    const MiltonFacadeDataProvider = await hre.ethers.getContractFactory(
        "MiltonFacadeDataProvider"
    );
    const miltonFacadeDataProvider = await MiltonFacadeDataProvider.deploy();
    await miltonFacadeDataProvider.initialize(
        iporOracle.address,
        [tokenDai.address, tokenUsdt.address, tokenUsdc.address],
        [miltonDai.address, miltonUsdt.address, miltonUsdc.address],
        [miltonStorageDai.address, miltonStorageUsdt.address, miltonStorageUsdc.address],
        [josephDai.address, josephUsdt.address, josephUsdc.address]
    );

    for (let i = 0; BigNumber.from(i).lt(numberOfSwapsToCreate); i++) {
        if (i % 2 === 0) {
            paramsDai.acceptableFixedInterestRate = BigNumber.from("9").mul(N0__1_18DEC);
            await openSwapPayFixed(testData, paramsDai);
        } else {
            paramsDai.acceptableFixedInterestRate = N0__01_18DEC;
            await openSwapReceiveFixed(testData, paramsDai);
        }
    }

    //when
    if (expectedError == null) {
        const response = await miltonFacadeDataProvider
            .connect(paramsDai.from)
            .getMySwaps(paramsDai.asset, offset, pageSize);

        const actualSwapsLength = response.swaps.length;
        const totalSwapCount = response.totalCount;

        //then
        expect(actualSwapsLength).to.be.eq(expectedResponseSize);
        expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
    } else {
        await assertError(
            miltonFacadeDataProvider
                .connect(paramsDai.from)
                .getMySwaps(paramsDai.asset, offset, pageSize),
            expectedError
        );
    }
};

export type SoapIndicatorsMemory = {
    rebalanceTimestamp: BigNumber;
    //N_0
    totalNotional: BigNumber;
    //I_0
    averageInterestRate: BigNumber;
    //TT
    totalIbtQuantity: BigNumber;
    //O_0, value without division by D18 * Constants.YEAR_IN_SECONDS
    quasiHypotheticalInterestCumulative: BigNumber;
};

export const assertSoapIndicator = async (
    actualSoapIndicator: SoapIndicatorsMemory,
    expectedRebalanceTimestamp: BigNumber,
    expectedTotalNotional: BigNumber,
    expectedTotalIbtQuantity: BigNumber,
    expectedAverageInterestRate: BigNumber,
    expectedQuasiHypotheticalInterestCumulative: BigNumber
) => {
    expect(expectedRebalanceTimestamp, "Incorrect rebalance timestamp").to.be.eq(
        actualSoapIndicator.rebalanceTimestamp
    );

    expect(expectedTotalNotional, "Incorrect total notional").to.be.eq(
        actualSoapIndicator.totalNotional
    );
    expect(expectedTotalIbtQuantity, "Incorrect total IBT quantity").to.be.eq(
        actualSoapIndicator.totalIbtQuantity
    );
    expect(expectedAverageInterestRate, "Incorrect average weighted interest rate").to.be.eq(
        actualSoapIndicator.averageInterestRate
    );
    expect(
        expectedQuasiHypotheticalInterestCumulative,
        "Incorrect quasi hypothetical interest cumulative"
    ).to.be.eq(actualSoapIndicator.quasiHypotheticalInterestCumulative);
};

export const assertExpectedValues = async function (
    testData: TestData,
    asset: string,
    direction: number,
    openerUser: Signer,
    closerUser: Signer,
    miltonBalanceBeforePayout: BigNumber,
    expectedMiltonUnderlyingTokenBalance: BigNumber,
    expectedOpenerUserUnderlyingTokenBalanceAfterPayOut: BigNumber,
    expectedCloserUserUnderlyingTokenBalanceAfterPayOut: BigNumber,
    expectedLiquidityPoolTotalBalanceWad: BigNumber,
    expectedOpenedPositions: BigNumber,
    expectedDerivativesTotalBalanceWad: BigNumber,
    expectedTreasuryTotalBalanceWad: BigNumber
) {
    let actualDerivatives: Derivatives | undefined;
    if (testData.miltonStorageUsdt && testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        if (direction == 0) {
            actualDerivatives = await testData.miltonStorageUsdt.getSwapsPayFixed(
                await openerUser.getAddress(),
                0,
                50
            );
        }
        if (direction == 1) {
            actualDerivatives = await testData.miltonStorageUsdt.getSwapsReceiveFixed(
                await openerUser.getAddress(),
                0,
                50
            );
        }
    }

    if (testData.miltonStorageUsdc && testData.tokenUsdc && asset === testData.tokenUsdc.address) {
        if (direction == 0) {
            actualDerivatives = await testData.miltonStorageUsdc.getSwapsPayFixed(
                await openerUser.getAddress(),
                0,
                50
            );
        }
        if (direction == 1) {
            actualDerivatives = await testData.miltonStorageUsdc.getSwapsReceiveFixed(
                await openerUser.getAddress(),
                0,
                50
            );
        }
    }

    if (testData.miltonStorageDai && testData.tokenDai && asset === testData.tokenDai.address) {
        if (direction == 0) {
            actualDerivatives = await testData.miltonStorageDai.getSwapsPayFixed(
                await openerUser.getAddress(),
                0,
                50
            );
        }
        if (direction == 1) {
            actualDerivatives = await testData.miltonStorageDai.getSwapsReceiveFixed(
                await openerUser.getAddress(),
                0,
                50
            );
        }
    }

    const actualOpenSwapsVol = countOpenSwaps(actualDerivatives);

    expect(
        expectedOpenedPositions,
        `Incorrect number of opened derivatives, actual:  ${actualOpenSwapsVol}, expected: ${expectedOpenedPositions}`
    ).to.be.eq(actualOpenSwapsVol);

    let expectedPublicationFeeTotalBalanceWad = USD_10_18DEC;
    let openerUserUnderlyingTokenBalanceBeforePayout = null;
    let closerUserUnderlyingTokenBalanceBeforePayout = null;
    let miltonUnderlyingTokenBalanceAfterPayout = null;
    let openerUserUnderlyingTokenBalanceAfterPayout = ZERO;
    let closerUserUnderlyingTokenBalanceAfterPayout = null;

    if (testData.miltonDai && testData.tokenDai && asset === testData.tokenDai.address) {
        openerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_18DEC;
        closerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_18DEC;

        miltonUnderlyingTokenBalanceAfterPayout = await testData.tokenDai.balanceOf(
            testData.miltonDai.address
        );
        openerUserUnderlyingTokenBalanceAfterPayout = await testData.tokenDai.balanceOf(
            await openerUser.getAddress()
        );
        closerUserUnderlyingTokenBalanceAfterPayout = await testData.tokenDai.balanceOf(
            await closerUser.getAddress()
        );
    }

    if (testData.miltonUsdt && testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        openerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_6DEC;
        closerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_6DEC;
        miltonUnderlyingTokenBalanceAfterPayout = await testData.tokenUsdt.balanceOf(
            testData.miltonUsdt.address
        );
        openerUserUnderlyingTokenBalanceAfterPayout = await testData.tokenUsdt.balanceOf(
            await openerUser.getAddress()
        );
        closerUserUnderlyingTokenBalanceAfterPayout = await testData.tokenUsdt.balanceOf(
            await closerUser.getAddress()
        );
    }

    await assertBalances(
        testData,
        asset,
        openerUser,
        closerUser,
        expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
        expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
        expectedMiltonUnderlyingTokenBalance,
        expectedDerivativesTotalBalanceWad,
        expectedPublicationFeeTotalBalanceWad,
        expectedLiquidityPoolTotalBalanceWad,
        expectedTreasuryTotalBalanceWad
    );

    let expectedSumOfBalancesBeforePayout = null;
    let actualSumOfBalances = null;

    if ((await openerUser.getAddress()) === (await closerUser.getAddress())) {
        expectedSumOfBalancesBeforePayout = miltonBalanceBeforePayout.add(
            openerUserUnderlyingTokenBalanceBeforePayout || ZERO
        );
        actualSumOfBalances = openerUserUnderlyingTokenBalanceAfterPayout.add(
            miltonUnderlyingTokenBalanceAfterPayout || ZERO
        );
    } else {
        expectedSumOfBalancesBeforePayout = miltonBalanceBeforePayout
            .add(openerUserUnderlyingTokenBalanceBeforePayout || ZERO)
            .add(closerUserUnderlyingTokenBalanceBeforePayout || ZERO);
        actualSumOfBalances = openerUserUnderlyingTokenBalanceAfterPayout
            .add(closerUserUnderlyingTokenBalanceAfterPayout || ZERO)
            .add(miltonUnderlyingTokenBalanceAfterPayout || ZERO);
    }

    expect(
        expectedSumOfBalancesBeforePayout,
        `Incorrect balance between AMM Balance and Users Balance for asset ${asset}, actual: ${actualSumOfBalances}, expected ${expectedSumOfBalancesBeforePayout}`
    ).to.be.equal(actualSumOfBalances);
};

const assertBalances = async (
    testData: TestData,
    asset: string,
    openerUser: Signer,
    closerUser: Signer,
    expectedOpenerUserUnderlyingTokenBalance: BigNumber,
    expectedCloserUserUnderlyingTokenBalance: BigNumber,
    expectedMiltonUnderlyingTokenBalance: BigNumber,
    expectedDerivativesTotalBalanceWad: BigNumber,
    expectedPublicationFeeTotalBalanceWad: BigNumber,
    expectedLiquidityPoolTotalBalanceWad: BigNumber,
    expectedTreasuryTotalBalanceWad: BigNumber
) => {
    let actualOpenerUserUnderlyingTokenBalance = null;
    let actualCloserUserUnderlyingTokenBalance = null;
    let balance = null;

    if (
        testData.miltonStorageDai &&
        testData.tokenDai &&
        testData.tokenDai &&
        asset === testData.tokenDai.address
    ) {
        actualOpenerUserUnderlyingTokenBalance = await testData.tokenDai.balanceOf(
            await openerUser.getAddress()
        );
        actualCloserUserUnderlyingTokenBalance = await testData.tokenDai.balanceOf(
            await closerUser.getAddress()
        );
        balance = await testData.miltonStorageDai.getExtendedBalance();
    }

    if (testData.miltonStorageUsdt && testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        actualOpenerUserUnderlyingTokenBalance = await testData.tokenUsdt.balanceOf(
            await openerUser.getAddress()
        );
        actualCloserUserUnderlyingTokenBalance = await testData.tokenUsdt.balanceOf(
            await closerUser.getAddress()
        );
        balance = await testData.miltonStorageUsdt.getExtendedBalance();
    }

    let actualMiltonUnderlyingTokenBalance = null;
    if (testData.miltonDai && testData.tokenDai && asset === testData.tokenDai.address) {
        actualMiltonUnderlyingTokenBalance = await testData.tokenDai.balanceOf(
            testData.miltonDai.address
        );
    }
    if (testData.miltonUsdt && testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        actualMiltonUnderlyingTokenBalance = await testData.tokenUsdt.balanceOf(
            testData.miltonUsdt.address
        );
    }
    if (testData.miltonUsdc && testData.tokenUsdc && asset === testData.tokenUsdc.address) {
        actualMiltonUnderlyingTokenBalance = await testData.tokenUsdc.balanceOf(
            testData.miltonUsdc.address
        );
    }

    const actualPayFixedDerivativesBalance = balance?.totalCollateralPayFixed;
    const actualRecFixedDerivativesBalance = balance?.totalCollateralReceiveFixed;
    const actualDerivativesTotalBalance = actualPayFixedDerivativesBalance?.add(
        actualRecFixedDerivativesBalance || ZERO
    );

    const actualPublicationFeeTotalBalance = balance?.iporPublicationFee;
    const actualLiquidityPoolTotalBalanceWad = balance?.liquidityPool;
    const actualTreasuryTotalBalanceWad = balance?.treasury;

    if (expectedMiltonUnderlyingTokenBalance !== null) {
        expect(
            actualMiltonUnderlyingTokenBalance,
            `Incorrect underlying token balance for ${asset} in Milton address, actual: ${actualMiltonUnderlyingTokenBalance}, expected: ${expectedMiltonUnderlyingTokenBalance}`
        ).to.be.eq(expectedMiltonUnderlyingTokenBalance);
    }

    if (expectedOpenerUserUnderlyingTokenBalance != null) {
        expect(
            actualOpenerUserUnderlyingTokenBalance,
            `Incorrect token balance for ${asset} in Opener User address, actual: ${actualOpenerUserUnderlyingTokenBalance}, expected: ${expectedOpenerUserUnderlyingTokenBalance}`
        ).to.be.eq(expectedOpenerUserUnderlyingTokenBalance);
    }

    if (expectedCloserUserUnderlyingTokenBalance != null) {
        expect(
            actualCloserUserUnderlyingTokenBalance,
            `Incorrect token balance for ${asset} in Closer User address, actual: ${actualCloserUserUnderlyingTokenBalance}, expected: ${expectedCloserUserUnderlyingTokenBalance}`
        ).to.be.eq(expectedCloserUserUnderlyingTokenBalance);
    }

    if (expectedDerivativesTotalBalanceWad != null) {
        expect(
            expectedDerivativesTotalBalanceWad,
            `Incorrect derivatives total balance for ${asset}, actual:  ${actualDerivativesTotalBalance}, expected: ${expectedDerivativesTotalBalanceWad}`
        ).to.be.eq(actualDerivativesTotalBalance);
    }

    if (expectedPublicationFeeTotalBalanceWad != null) {
        expect(
            expectedPublicationFeeTotalBalanceWad,
            `Incorrect ipor publication fee total balance for ${asset}, actual: ${actualPublicationFeeTotalBalance}, expected: ${expectedPublicationFeeTotalBalanceWad}`
        ).to.be.eq(actualPublicationFeeTotalBalance);
    }

    if (expectedLiquidityPoolTotalBalanceWad != null) {
        expect(
            expectedLiquidityPoolTotalBalanceWad,
            `Incorrect Liquidity Pool total balance for ${asset}, actual:  ${actualLiquidityPoolTotalBalanceWad}, expected: ${expectedLiquidityPoolTotalBalanceWad}`
        ).to.be.eq(actualLiquidityPoolTotalBalanceWad);
    }

    if (expectedTreasuryTotalBalanceWad != null) {
        expect(
            expectedTreasuryTotalBalanceWad,
            `Incorrect Treasury total balance for ${asset}, actual:  ${actualTreasuryTotalBalanceWad}, expected: ${expectedTreasuryTotalBalanceWad}`
        ).to.be.eq(actualTreasuryTotalBalanceWad);
    }
};

export const assertMiltonDerivativeItem = async (
    testData: TestData,
    asset: string,
    swapId: number,
    direction: number,
    expectedIdsIndex: number,
    expectedUserDerivativeIdsIndex: number
) => {
    let actualDerivativeItem: { id: BigNumber; idsIndex: BigNumber } = { id: ZERO, idsIndex: ZERO };
    if (testData.miltonStorageUsdt && testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        if (direction == 0) {
            actualDerivativeItem = await testData.miltonStorageUsdt.getSwapPayFixed(swapId);
        }

        if (direction == 1) {
            actualDerivativeItem = await testData.miltonStorageUsdt.getSwapReceiveFixed(swapId);
        }
    }
    if (testData.miltonStorageUsdc && testData.tokenUsdc && asset === testData.tokenUsdc.address) {
        if (direction == 0) {
            actualDerivativeItem = await testData.miltonStorageUsdc.getSwapPayFixed(swapId);
        }

        if (direction == 1) {
            actualDerivativeItem = await testData.miltonStorageUsdc.getSwapReceiveFixed(swapId);
        }
    }
    if (testData.miltonStorageDai && testData.tokenDai && asset === testData.tokenDai.address) {
        if (direction == 0) {
            actualDerivativeItem = await testData.miltonStorageDai.getSwapPayFixed(swapId);
        }

        if (direction == 1) {
            actualDerivativeItem = await testData.miltonStorageDai.getSwapReceiveFixed(swapId);
        }
    }

    expect(
        expectedUserDerivativeIdsIndex,
        `Incorrect idsIndex for swap id ${actualDerivativeItem?.id} actual: ${actualDerivativeItem.idsIndex}, expected: ${expectedUserDerivativeIdsIndex}`
    ).to.be.eq(actualDerivativeItem.idsIndex);
};
