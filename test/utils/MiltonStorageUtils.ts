import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { UsdcMockedToken, UsdtMockedToken, DaiMockedToken } from "../../types";
import { assertError } from "./AssertUtils";
import {
    TestData,
    prepareTestData,
    prepareApproveForUsers,
    setupTokenUsdtInitialValuesForUsers,
} from "./DataUtils";
import {
    N0__1_18DEC,
    N1__0_18DEC,
    PERCENTAGE_5_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    TC_TOTAL_AMOUNT_100_6DEC,
    LEVERAGE_18DEC,
    USD_50_000_6DEC,
} from "./Constants";
import {
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    MockMiltonSpreadModel,
} from "./MiltonUtils";

import { MockStanleyCase } from "./StanleyUtils";

import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "./JosephUtils";

const { expect } = chai;

export type Params = {
    asset: UsdcMockedToken | UsdtMockedToken | DaiMockedToken;
    totalAmount: BigNumber;
    maxAcceptableFixedInterestRate: BigNumber;
    leverage: BigNumber;
    direction: number;
    openTimestamp: BigNumber;
    from: Signer;
};

export const testCasePaginationPayFixed = async (
    users: Signer[],
    numberOfSwapsToCreate: BigNumber,
    offset: BigNumber,
    pageSize: BigNumber,
    expectedResponseSize: BigNumber,
    expectedError: string | null,
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    // given
    const { miltonStorageUsdt } = await preparePayFixedState(
        users,
        numberOfSwapsToCreate,
        miltonSpreadModel
    );
    if (miltonStorageUsdt === undefined) {
        expect(true).to.be.false;
        return;
    }
    const [, , userTwo] = users;
    //when
    if (expectedError == null) {
        const response = await miltonStorageUsdt.getSwapsPayFixed(
            await userTwo.getAddress(),
            offset,
            pageSize
        );

        const actualSwapsLength = response.swaps.length;
        const totalSwapCount = response.totalCount;

        //then
        expect(actualSwapsLength).to.be.eq(expectedResponseSize);
        expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
    } else {
        await assertError(
            miltonStorageUsdt.getSwapsPayFixed(await userTwo.getAddress(), offset, pageSize),
            expectedError
        );
    }
};

export const testCasePaginationReceiveFixed = async (
    users: Signer[],
    numberOfSwapsToCreate: BigNumber,
    offset: BigNumber,
    pageSize: BigNumber,
    expectedResponseSize: BigNumber,
    expectedError: string | null,
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    // given
    const { miltonStorageUsdt } = await prepareReceiveFixedState(
        users,
        numberOfSwapsToCreate,
        miltonSpreadModel
    );

    // if (miltonStorageUsdt === undefined) {
    //     expect(true).to.be.false;
    //     return;
    // }
    // const [, , userTwo] = users;
    // //when
    // if (expectedError == null) {
    //     const response = await miltonStorageUsdt.getSwapsReceiveFixed(
    //         await userTwo.getAddress(),
    //         offset,
    //         pageSize
    //     );

    //     const actualSwapsLength = response.swaps.length;
    //     const totalSwapCount = response.totalCount;

    //     //then
    //     expect(actualSwapsLength).to.be.eq(expectedResponseSize);
    //     expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
    // } else {
    //     await assertError(
    //         miltonStorageUsdt.getSwapsReceiveFixed(await userTwo.getAddress(), offset, pageSize),
    //         expectedError
    //     );
    // }
};

export const testCaseIdsPaginationPayFixed = async (
    users: Signer[],
    numberOfSwapsToCreate: BigNumber,
    offset: BigNumber,
    pageSize: BigNumber,
    expectedResponseSize: BigNumber,
    expectedError: string | null,
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    // given
    const { miltonStorageUsdt } = await preparePayFixedState(
        users,
        numberOfSwapsToCreate,
        miltonSpreadModel
    );
    if (miltonStorageUsdt === undefined) {
        expect(true).to.be.false;
        return;
    }
    const [, , userTwo] = users;
    //when
    if (expectedError == null) {
        const response = await miltonStorageUsdt.getSwapPayFixedIds(
            await userTwo.getAddress(),
            offset,
            pageSize
        );

        const actualSwapsLength = response.ids.length;
        const totalSwapCount = response.totalCount;

        //then
        expect(actualSwapsLength).to.be.eq(expectedResponseSize);
        expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
    } else {
        await assertError(
            miltonStorageUsdt.getSwapsPayFixed(await userTwo.getAddress(), offset, pageSize),
            expectedError
        );
    }
};

export const testCaseIdsPaginationReceiveFixed = async (
    users: Signer[],
    numberOfSwapsToCreate: BigNumber,
    offset: BigNumber,
    pageSize: BigNumber,
    expectedResponseSize: BigNumber,
    expectedError: string | null,
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    // given
    const { miltonStorageUsdt } = await prepareReceiveFixedState(
        users,
        numberOfSwapsToCreate,
        miltonSpreadModel
    );
    if (miltonStorageUsdt === undefined) {
        expect(true).to.be.false;
        return;
    }
    const [, , userTwo] = users;
    //when
    if (expectedError == null) {
        const response = await miltonStorageUsdt.getSwapReceiveFixedIds(
            await userTwo.getAddress(),
            offset,
            pageSize
        );

        const actualSwapsLength = response.ids.length;
        const totalSwapCount = response.totalCount;

        //then
        expect(actualSwapsLength).to.be.eq(expectedResponseSize);
        expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
    } else {
        await assertError(
            miltonStorageUsdt.getSwapsReceiveFixed(await userTwo.getAddress(), offset, pageSize),
            expectedError
        );
    }
};

export const testCaseIdsPagination = async (
    users: Signer[],
    numberOfPayFixedSwapsToCreate: BigNumber,
    numberOfReceiveFixedSwapsToCreate: BigNumber,
    offset: BigNumber,
    pageSize: BigNumber,
    expectedResponseSize: BigNumber,
    expectedError: string | null,
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    // given
    const { miltonStorageUsdt } = await prepareState(
        users,
        numberOfPayFixedSwapsToCreate,
        numberOfReceiveFixedSwapsToCreate,
        miltonSpreadModel
    );

    if (miltonStorageUsdt === undefined) {
        expect(true).to.be.false;
        return;
    }
    const [, , userTwo] = users;

    //when
    if (expectedError == null) {
        const response = await miltonStorageUsdt.getSwapIds(
            await userTwo.getAddress(),
            offset,
            pageSize
        );

        const actualSwapsLength = response.ids.length;
        const totalSwapCount = response.totalCount;

        //then
        expect(actualSwapsLength).to.be.eq(expectedResponseSize);
        expect(totalSwapCount).to.be.eq(
            numberOfPayFixedSwapsToCreate.add(numberOfReceiveFixedSwapsToCreate)
        );
    } else {
        await assertError(
            miltonStorageUsdt.getSwapsReceiveFixed(await userTwo.getAddress(), offset, pageSize),
            expectedError
        );
    }
};

export const openSwapPayFixed = async (testData: TestData, params: Params) => {
    if (
        testData.miltonUsdt &&
        testData.tokenUsdt &&
        params.asset.address === testData.tokenUsdt.address
    ) {
        await testData.miltonUsdt
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );
    }

    if (
        testData.miltonUsdc &&
        testData.tokenUsdc &&
        params.asset.address === testData.tokenUsdc.address
    ) {
        await testData.miltonUsdc
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );
    }

    if (
        testData.miltonDai &&
        testData.tokenDai &&
        params.asset.address === testData.tokenDai.address
    ) {
        await testData.miltonDai
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );
    }
};

export const openSwapReceiveFixed = async (testData: TestData, params: Params) => {
    if (
        testData.miltonUsdc &&
        testData.tokenUsdc &&
        params.asset.address === testData.tokenUsdc.address
    ) {
        await testData.miltonUsdc
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );
    }

    if (
        testData.miltonUsdt &&
        testData.tokenUsdt &&
        params.asset.address === testData.tokenUsdt.address
    ) {
        await testData.miltonUsdt
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );
    }

    if (
        testData.miltonDai &&
        testData.tokenDai &&
        params.asset.address === testData.tokenDai.address
    ) {
        await testData.miltonDai
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );
    }
};

export const preprareSwapPayFixedStruct18DecSimpleCase1 = async (userTwo: Signer) => {
    const openingTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
    const closeSwapTimestamp = openingTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

    return {
        state: 0,
        buyer: await userTwo.getAddress(),
        openTimestamp: openingTimestamp,
        endTimestamp: closeSwapTimestamp,
        id: BigNumber.from("1"),
        collateral: BigNumber.from("1000").mul(N1__0_18DEC),
        liquidationDepositAmount: BigNumber.from("20").mul(N1__0_18DEC),
        notional: BigNumber.from("50000").mul(N1__0_18DEC),
        fixedInterestRate: BigNumber.from("234"),
        ibtQuantity: BigNumber.from("123"),
        openingFeeLPAmount: BigNumber.from("1500").mul(N1__0_18DEC),
        openingFeeTreasuryAmount: BigNumber.from("1500").mul(N1__0_18DEC),
    };
};
// [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress]
const preparePayFixedState = async (
    users: Signer[],
    numberOfSwapsToCreate: BigNumber,
    miltonSpreadModel: MockMiltonSpreadModel
): Promise<TestData> => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] = users;
    const testData = await prepareTestData(
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
        ["USDT"],
        miltonSpreadModel,
        MiltonUsdcCase.CASE0,
        MiltonUsdtCase.CASE0,
        MiltonDaiCase.CASE0,
        MockStanleyCase.CASE1,
        JosephUsdcMockCases.CASE0,
        JosephUsdtMockCases.CASE0,
        JosephDaiMockCases.CASE0
    );

    const { tokenUsdt, josephUsdt, iporOracle } = testData;

    if (tokenUsdt === undefined || josephUsdt === undefined) {
        expect(true).to.be.false;
        return testData;
    }

    await prepareApproveForUsers(
        [userOne, userTwo, userThree, liquidityProvider],
        "USDT",
        testData
    );
    await setupTokenUsdtInitialValuesForUsers(
        [admin, userOne, userTwo, liquidityProvider],
        tokenUsdt
    );

    const paramsUsdt = {
        asset: tokenUsdt,
        totalAmount: TC_TOTAL_AMOUNT_100_6DEC,
        maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
        leverage: LEVERAGE_18DEC,
        direction: 0,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: userTwo,
    };

    await iporOracle
        .connect(userOne)
        .itfUpdateIndex(paramsUsdt.asset.address, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

    await josephUsdt
        .connect(liquidityProvider)
        .itfProvideLiquidity(USD_50_000_6DEC, paramsUsdt.openTimestamp);

    for (let i = 0; BigNumber.from(i).lt(numberOfSwapsToCreate); i++) {
        await openSwapPayFixed(testData, paramsUsdt);
    }

    return testData;
};

const prepareReceiveFixedState = async (
    users: Signer[],
    numberOfSwapsToCreate: BigNumber,
    miltonSpreadModel: MockMiltonSpreadModel
): Promise<TestData> => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] = users;
    const testData = await prepareTestData(
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
        ["USDT", "USDC", "DAI"],
        miltonSpreadModel,
        MiltonUsdcCase.CASE0,
        MiltonUsdtCase.CASE0,
        MiltonDaiCase.CASE0,
        MockStanleyCase.CASE1,
        JosephUsdcMockCases.CASE0,
        JosephUsdtMockCases.CASE0,
        JosephDaiMockCases.CASE0
    );

    const { tokenUsdt, iporOracle, josephUsdt } = testData;

    if (tokenUsdt === undefined || josephUsdt === undefined) {
        expect(true).to.be.false;
        return testData;
    }

    await prepareApproveForUsers(
        [userOne, userTwo, userThree, liquidityProvider],
        "USDT",
        testData
    );
    await setupTokenUsdtInitialValuesForUsers(
        [admin, userOne, userTwo, liquidityProvider],
        tokenUsdt
    );

    const paramsUsdt = {
        asset: tokenUsdt,
        totalAmount: TC_TOTAL_AMOUNT_100_6DEC,
        maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
        leverage: LEVERAGE_18DEC,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        direction: 0,
        from: userTwo,
    };

    await iporOracle
        .connect(userOne)
        .itfUpdateIndex(paramsUsdt.asset.address, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

    await josephUsdt
        .connect(liquidityProvider)
        .itfProvideLiquidity(USD_50_000_6DEC, paramsUsdt.openTimestamp);

    for (let i = 0; BigNumber.from(i).lt(numberOfSwapsToCreate); i++) {
        await openSwapReceiveFixed(testData, paramsUsdt);
    }

    return testData;
};

const prepareState = async (
    users: Signer[],
    numberOfPayFixedSwapsToCreate: BigNumber,
    numberOfReceiveFixedSwapsToCreate: BigNumber,
    miltonSpreadModel: MockMiltonSpreadModel
): Promise<TestData> => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] = users;
    const testData = await prepareTestData(
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
        ["USDT", "USDC", "DAI"],
        miltonSpreadModel,
        MiltonUsdcCase.CASE0,
        MiltonUsdtCase.CASE0,
        MiltonDaiCase.CASE0,
        MockStanleyCase.CASE1,
        JosephUsdcMockCases.CASE0,
        JosephUsdtMockCases.CASE0,
        JosephDaiMockCases.CASE0
    );

    await prepareApproveForUsers(
        [userOne, userTwo, userThree, liquidityProvider],
        "USDT",
        testData
    );

    const { tokenUsdt, josephUsdt } = testData;

    if (tokenUsdt === undefined || josephUsdt === undefined) {
        expect(true).to.be.false;
        return testData;
    }

    await setupTokenUsdtInitialValuesForUsers(
        [admin, userOne, userTwo, liquidityProvider],
        tokenUsdt
    );

    const paramsUsdt = {
        asset: tokenUsdt,
        totalAmount: TC_TOTAL_AMOUNT_100_6DEC,
        maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
        leverage: LEVERAGE_18DEC,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: userTwo,
        direction: 0,
    };

    await testData.iporOracle
        .connect(userOne)
        .itfUpdateIndex(paramsUsdt.asset.address, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

    await josephUsdt
        .connect(liquidityProvider)
        .itfProvideLiquidity(USD_50_000_6DEC, paramsUsdt.openTimestamp);

    for (let i = 0; BigNumber.from(i).lt(numberOfPayFixedSwapsToCreate); i++) {
        await openSwapPayFixed(testData, paramsUsdt);
    }
    for (let i = 0; BigNumber.from(i).lt(numberOfReceiveFixedSwapsToCreate); i++) {
        await openSwapReceiveFixed(testData, paramsUsdt);
    }

    return testData;
};
