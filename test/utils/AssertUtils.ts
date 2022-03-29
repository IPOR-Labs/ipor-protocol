import chai from "chai";
import { BigNumber, Signer } from "ethers";

import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
} from "./DataUtils";
import {
    MockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "./MiltonUtils";

import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "./JosephUtils";
import { MockStanleyCase } from "./StanleyUtils";
import { openSwapPayFixed, openSwapReceiveFixed } from "./SwapUtiles";

import {
    N0__1_18DEC,
    TC_TOTAL_AMOUNT_100_18DEC,
    LEVERAGE_18DEC,
    PERCENTAGE_5_18DEC,
    USD_50_000_18DEC,
} from "./Constants";

const { expect } = chai;

// ########################################################################################################
//                                           assert
// ########################################################################################################

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
// [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress]
export const testCasePagination = async (
    users: Signer[],
    numberOfSwapsToCreate: BigNumber,
    offset: BigNumber,
    pageSize: BigNumber,
    expectedResponseSize: BigNumber,
    expectedError: string | null,
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    //given
    const testData = await prepareTestData(
        users,
        ["DAI", "USDC", "USDT"],
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
        warren,
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
        asset: tokenDai,
        totalAmount: TC_TOTAL_AMOUNT_100_18DEC,
        toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
        leverage: LEVERAGE_18DEC,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: userTwo,
    };

    await warren
        .connect(userOne)
        .itfUpdateIndex(paramsDai.asset.address, PERCENTAGE_5_18DEC, paramsDai.openTimestamp);

    await josephDai
        .connect(liquidityProvider)
        .itfProvideLiquidity(USD_50_000_18DEC, paramsDai.openTimestamp);

    const MiltonFacadeDataProvider = await hre.ethers.getContractFactory(
        "MiltonFacadeDataProvider"
    );
    const miltonFacadeDataProvider = await MiltonFacadeDataProvider.deploy();
    await miltonFacadeDataProvider.initialize(
        warren.address,
        [tokenDai.address, tokenUsdt.address, tokenUsdc.address],
        [miltonDai.address, miltonUsdt.address, miltonUsdc.address],
        [miltonStorageDai.address, miltonStorageUsdt.address, miltonStorageUsdc.address],
        [josephDai.address, josephUsdt.address, josephUsdc.address]
    );

    for (let i = 0; BigNumber.from(i).lt(numberOfSwapsToCreate); i++) {
        if (i % 2 === 0) {
            await openSwapPayFixed(testData, paramsDai);
        } else {
            await openSwapReceiveFixed(testData, paramsDai);
        }
    }

    //when
    if (expectedError == null) {
        const response = await miltonFacadeDataProvider
            .connect(paramsDai.from)
            .getMySwaps(paramsDai.asset.address, offset, pageSize);

        const actualSwapsLength = response.swaps.length;
        const totalSwapCount = response.totalCount;

        //then
        expect(actualSwapsLength).to.be.eq(expectedResponseSize);
        expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
    } else {
        await assertError(
            miltonFacadeDataProvider
                .connect(paramsDai.from)
                .getMySwaps(paramsDai.asset.address, offset, pageSize),
            expectedError
        );
    }
};
