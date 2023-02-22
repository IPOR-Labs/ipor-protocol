import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    LEG_PAY_FIXED,
    LEG_RECEIVE_FIXED,
    ZERO,
    N0__01_18DEC,
    USD_10_18DEC,
    USD_28_000_18DEC,
    PERCENTAGE_3_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    TC_COLLATERAL_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_120_18DEC,
    PERIOD_50_DAYS_IN_SECONDS,
    PERIOD_14_DAYS_IN_SECONDS,
    N0__1_18DEC,
} from "../utils/Constants";
import {
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    testCaseWhenMiltonEarnAndUserLost,
    testCaseWhenMiltonLostAndUserEarn,
    prepareMockSpreadModel,
} from "../utils/MiltonUtils";
import { openSwapPayFixed } from "../utils/SwapUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import {
    prepareComplexTestDataDaiCase000,
    getPayFixedDerivativeParamsDAICase1,
    prepareApproveForUsers,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
} from "../utils/DataUtils";

const { expect } = chai;

describe.skip("Milton should calculate income - Core", () => {
    let miltonSpreadModel: MockSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
    });

    beforeEach(async () => {
        miltonSpreadModel = await prepareMockSpreadModel(
            BigNumber.from(4).mul(N0__01_18DEC),
            BigNumber.from("2").mul(N0__01_18DEC),
            ZERO,
            ZERO
        );
    });

    it("should calculate income fee 5%, receive fixed, not owner, Milton loses, user earns, |I| < D", async () => {
        const quote = N0__1_18DEC;
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_120_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE2,
            MiltonUsdtCase.CASE2,
            MiltonDaiCase.CASE2,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("34133595537777021487");
        const expectedIncomeFeeValueWad = BigNumber.from("34133595537777021487");
        const expectedPayoff = BigNumber.from("682671910755540429746");
        const expectedPayoffWad = BigNumber.from("682671910755540429746");

        testData.miltonDai?.addSwapLiquidator(await userThree.getAddress());

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should calculate income fee 5%, pay fixed, Milton loses, user earns, |I| > D", async () => {
        const quote = BigNumber.from("6").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE2,
            MiltonUsdtCase.CASE2,
            MiltonDaiCase.CASE2,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const expectedIncomeFeeValue = BigNumber.from("498350494851544536639");
        const expectedIncomeFeeValueWad = BigNumber.from("498350494851544536639");

        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        testData.miltonDai?.addSwapLiquidator(await userTwo.getAddress());

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should calculate income fee 5%, pay fixed, Milton earns, user loses, |I| < D", async () => {
        const quote = BigNumber.from("121").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_120_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE2,
            MiltonUsdtCase.CASE2,
            MiltonDaiCase.CASE2,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("395949708238213469173");
        const expectedPayoff = BigNumber.from("-7918994164764269383465");
        const expectedPayoffWad = BigNumber.from("-7918994164764269383465");

        testData.miltonDai?.addSwapLiquidator(await userTwo.getAddress());

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should calculate income fee 5%, receive fixed, Milton earns, user loses, |I| > D", async () => {
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE2,
            MiltonUsdtCase.CASE2,
            MiltonDaiCase.CASE2,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("498350494851544536639");
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        testData.miltonDai?.addSwapLiquidator(await userThree.getAddress());

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should calculate income fee 100%, receive fixed, Milton loses, user earns, |I| < D, after maturity", async () => {
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_120_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("682671910755540429746");
        const expectedIncomeFeeValueWad = BigNumber.from("682671910755540429746");
        const expectedPayoff = expectedIncomeFeeValue;
        const expectedPayoffWad = expectedIncomeFeeValueWad;

        testData.miltonDai?.addSwapLiquidator(await userThree.getAddress());

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should calculate income fee 100%, pay fixed, Milton loses, user earns, |I| > D, before maturity", async () => {
        const quote = BigNumber.from("6").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const expectedIncomeFeeValue = TC_COLLATERAL_18DEC;
        const expectedIncomeFeeValueWad = TC_COLLATERAL_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        testData.miltonDai?.addSwapLiquidator(await userTwo.getAddress());

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should calculate income fee 100%, pay fixed, Milton earns, user loses, |I| < D, before maturity", async () => {
        const quote = BigNumber.from("121").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_120_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("7918994164764269383465");
        const expectedPayoff = BigNumber.from("-7918994164764269383465");
        const expectedPayoffWad = BigNumber.from("-7918994164764269383465");

        testData.miltonDai?.addSwapLiquidator(await userTwo.getAddress());

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should calculate income fee 100%, receive fixed, Milton earns, user loses, |I| > D, after maturity", async () => {
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE3,
            MiltonUsdtCase.CASE3,
            MiltonDaiCase.CASE3,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const expectedIncomeFeeValueWad = TC_COLLATERAL_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        testData.miltonDai?.addSwapLiquidator(await userThree.getAddress());

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            acceptableFixedInterestRate,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should calculate Pay Fixed Position Value - simple case 1", async () => {
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));

        //given
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai, miltonStorageDai } = testData;

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC;

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);

        await openSwapPayFixed(testData, params);

        const derivativeItem = await miltonStorageDai.getSwapPayFixed(1);

        const expectedPayoff = BigNumber.from("-38229627002310297226");

        //when
        const actualPayoff = BigNumber.from(
            await miltonDai.itfCalculateSwapPayFixedValue(
                params.openTimestamp.add(PERIOD_14_DAYS_IN_SECONDS),
                derivativeItem.id
            )
        );

        //then
        expect(
            expectedPayoff,
            `Incorrect position value, actual: ${actualPayoff}, expected: ${expectedPayoff}`
        ).to.be.eq(actualPayoff);
    });
});
