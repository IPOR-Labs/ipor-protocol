import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    LEG_PAY_FIXED,
    LEG_RECEIVE_FIXED,
    ZERO,
    USD_10_18DEC,
    LEVERAGE_1000_18DEC,
    USD_28_000_18DEC,
    USD_50_000_18DEC,
    PERCENTAGE_3_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    N0__1_18DEC,
    N1__0_18DEC,
    N0__01_18DEC,
    TC_OPENING_FEE_18DEC,
    TC_COLLATERAL_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USER_SUPPLY_10MLN_18DEC,
    TC_INCOME_TAX_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_5_18DEC,
    TC_COLLATERAL_6DEC,
    PERCENTAGE_120_18DEC,
    PERIOD_50_DAYS_IN_SECONDS,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_50_18DEC,
    SPECIFIC_INTEREST_AMOUNT_CASE_1,
    SPECIFIC_INCOME_TAX_CASE_1,
    PERCENTAGE_151_18DEC,
    PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
    PERCENTAGE_150_18DEC,
    USD_1_000_000_18DEC,
    USD_10_000_000_18DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_28_DAYS_IN_SECONDS, PERIOD_27_DAYS_17_HOURS_IN_SECONDS,
} from "../utils/Constants";
import {
    prepareMockSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    testCaseWhenMiltonEarnAndUserLost,
    testCaseWhenMiltonLostAndUserEarn,
} from "../utils/MiltonUtils";
import {
    openSwapPayFixed,
    openSwapReceiveFixed,
    executeCloseSwapsTestCase,
    countOpenSwaps,
    assertSoap,
} from "../utils/SwapUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import {
    prepareComplexTestDataDaiCase000,
    getPayFixedDerivativeParamsDAICase1,
    getReceiveFixedDerivativeParamsDAICase1,
    prepareApproveForUsers,
    prepareTestData,
    setupTokenUsdtInitialValuesForUsers,
    setupTokenDaiInitialValuesForUsers,
} from "../utils/DataUtils";
import { assertError, assertExpectedValues } from "../utils/AssertUtils";

const { expect } = chai;

describe("Milton - close position", () => {
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
            BigNumber.from("6").mul(N0__01_18DEC),
            BigNumber.from("4").mul(N0__01_18DEC),
            ZERO,
            ZERO
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Collateral, before maturity, DAI 18 decimals", async () => {
        const quote = BigNumber.from("161").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

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
        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost > Collateral, before maturity, USDT 6 decimals", async () => {
        const quote = BigNumber.from("400").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            [PERCENTAGE_160_18DEC],
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

        const { tokenUsdt } = testData;
        if (tokenUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_6DEC.mul(-1);
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(-1);

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenUsdt.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_3_18DEC,
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
        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Collateral, before maturity, DAI 18 decimals", async () => {
        const quote = BigNumber.from("121").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("791899416476426938347");
        const expectedPayoff = BigNumber.from("-7918994164764269383465");
        const expectedPayoffWad = BigNumber.from("-7918994164764269383465");

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
        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost < Collateral, before maturity, USDT 6 decimals", async () => {
        //given
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            [PERCENTAGE_120_18DEC],
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

        const { tokenUsdt } = testData;
        if (tokenUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const expectedIncomeFeeValueWad = BigNumber.from("34133595537777026471");
        const expectedPayoff = BigNumber.from("-341335955");
        const expectedPayoffWad = BigNumber.from("-341335955377770264707");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenUsdt.address,
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
        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Collateral, after maturity", async () => {
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("68267191075554042975");
        const expectedPayoff = BigNumber.from("-682671910755540429745");
        const expectedPayoffWad = BigNumber.from("-682671910755540429745");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
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

        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Collateral, before maturity, DAI 18 decimals", async () => {
        const quote = BigNumber.from("1").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

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

        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned > Collateral, before maturity, USDT 6 decimals", async () => {
        const quote = BigNumber.from("1").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            [PERCENTAGE_5_18DEC],
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

        const { tokenUsdt } = testData;
        if (tokenUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const expectedIncomeFeeValue = BigNumber.from("996700990");
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_6DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenUsdt.address,
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
        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Collateral, before maturity, DAI 18 decimals", async () => {
        const quote = BigNumber.from("6").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("778245978261316123526");
        const expectedIncomeFeeValueWad = BigNumber.from("778245978261316123526");

        const expectedPayoff = BigNumber.from("7782459782613161235257");
        const expectedPayoffWad = BigNumber.from("7782459782613161235257");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
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
        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned < Collateral, before maturity, USDT 6 decimals", async () => {
        const quote = BigNumber.from("3").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            [PERCENTAGE_5_18DEC],
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

        const { tokenUsdt } = testData;
        if (tokenUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const expectedIncomeFeeValue = BigNumber.from("20480157");
        const expectedIncomeFeeValueWad = BigNumber.from("20480157322666209738");
        const expectedPayoff = BigNumber.from("204801573");
        const expectedPayoffWad = BigNumber.from("204801573226662097384");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenUsdt.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_6_18DEC,
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
        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Collateral, after maturity", async () => {
        const quote = BigNumber.from("1").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
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

        //Internal check if test itself is ok.
        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Collateral, after maturity", async () => {
        const quote = BigNumber.from("6").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedIncomeFeeValueWad = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedPayoff = SPECIFIC_INTEREST_AMOUNT_CASE_1;
        const expectedPayoffWad = SPECIFIC_INTEREST_AMOUNT_CASE_1;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_50_18DEC,
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

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("1").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userThree,
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

    it("should close position, DAI, not owner, pay fixed, Milton lost, 100% Collateral > User earned > 99% Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("6").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("989874270595533665253");
        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533665253");
        const expectedPayoff = BigNumber.from("9898742705955336652531");
        const expectedPayoffWad = BigNumber.from("9898742705955336652531");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_151_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Collateral, 5 hours before maturity", async () => {
        //given
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("37945180372828793181");
        const expectedIncomeTaxValueWad = BigNumber.from("37945180372828793181");
        const expectedPayoff = BigNumber.from("379451803728287931809");
        const expectedPayoffWad = BigNumber.from("379451803728287931809");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Collateral, after maturity", async () => {
        const quote = BigNumber.from("1").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
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
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned < Collateral, after maturity", async () => {
        const quote = BigNumber.from("6").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedIncomeFeeValueWad = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedPayoff = SPECIFIC_INTEREST_AMOUNT_CASE_1;
        const expectedPayoffWad = SPECIFIC_INTEREST_AMOUNT_CASE_1;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_50_18DEC,
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

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Collateral, before maturity", async () => {
        const quote = BigNumber.from("161").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userThree,
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

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, 100% Collateral > User lost > 99% Collateral, before maturity", async () => {
        const quote = BigNumber.from("151").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_150_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533672762");
        const expectedPayoff = BigNumber.from("-9898742705955336727624");
        const expectedPayoffWad = BigNumber.from("-9898742705955336727624");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_6_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Collateral, after maturity", async () => {
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("68267191075554042975");
        const expectedPayoff = BigNumber.from("-682671910755540429745");
        const expectedPayoffWad = BigNumber.from("-682671910755540429745");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
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
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Collateral, 5 hours before maturity", async () => {
        const quote = BigNumber.from("121").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValueWad = BigNumber.from("880328184649627945216");
        const expectedPayoff = BigNumber.from("-8803281846496279452160");
        const expectedPayoffWad = BigNumber.from("-8803281846496279452160");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Collateral, after maturity", async () => {
        const quote = BigNumber.from("161").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
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
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Collateral, before maturity", async () => {
        const quote = BigNumber.from("159").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
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
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("1").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("34133595537777018961");
        const expectedPayoff = BigNumber.from("-341335955377770189613");
        const expectedPayoffWad = BigNumber.from("-341335955377770189613");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_6_18DEC,
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

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Collateral, before maturity", async () => {
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
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
            expectedIncomeFeeValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Collateral, before maturity", async () => {
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("791899416476426932749");
        const expectedPayoff = BigNumber.from("-7918994164764269327486");
        const expectedPayoffWad = BigNumber.from("-7918994164764269327486");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
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

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Collateral, after maturity", async () => {
        const quote = BigNumber.from("159").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
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

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned < Collateral, after maturity", async () => {
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("68267191075554042975");
        const expectedIncomeFeeValueWad = BigNumber.from("68267191075554042975");
        const expectedPayoff = BigNumber.from("682671910755540429746");
        const expectedPayoffWad = BigNumber.from("682671910755540429746");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
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

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Collateral, after maturity", async () => {
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
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

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Collateral, after maturity", async () => {
        const quote = BigNumber.from("3").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);

        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedIncomeFeeValueWad = BigNumber.from("641711596110208034982");
        const expectedPayoff = BigNumber.from("-6417115961102080349821");
        const expectedPayoffWad = BigNumber.from("-6417115961102080349821");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_50_18DEC,
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

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Collateral, before maturity", async () => {
        const quote = BigNumber.from("159").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
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

    it("should close position, DAI, not owner, receive fixed, Milton lost, 100% Collateral > User earned > 99% Collateral, before maturity", async () => {
        const quote = BigNumber.from("150").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_151_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("989874270595533672080");
        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533672080");
        const expectedPayoff = BigNumber.from("9898742705955336720799");
        const expectedPayoffWad = BigNumber.from("9898742705955336720799");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
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

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("[!] should close position, DAI, not owner, receive fixed, Milton earned, 100% Collateral > User lost > 99% Collateral, before maturity", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValueWad = BigNumber.from("996700989703089070547");
        const expectedPayoff = BigNumber.from("-9967009897030890705472");
        const expectedPayoffWad = BigNumber.from("-9967009897030890705472");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            BigNumber.from("150").mul(N0__01_18DEC),
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPayoff,
            expectedPayoffWad,
            userOne,
            liquidityProvider
        );

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("159").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC;
        const expectedPayoffWad = TC_COLLATERAL_18DEC;

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

        expect(expectedPayoffWad.abs()).to.be.equal(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("10").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_120_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("68267191075554042975");
        const expectedIncomeFeeValueWad = BigNumber.from("68267191075554042975");
        const expectedPayoff = BigNumber.from("682671910755540429746");
        const expectedPayoffWad = BigNumber.from("682671910755540429746");

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

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

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

    it.skip("should close position, DAI, not owner, receive fixed, Milton earned, User lost < Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("628058157895097225759");
        const expectedPayoff = BigNumber.from("-6280581578950972257591");
        const expectedPayoffWad = BigNumber.from("-6280581578950972257591");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userThree,
            PERCENTAGE_50_18DEC,
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

        expect(expectedPayoffWad.abs()).to.be.lt(TC_COLLATERAL_18DEC);
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Collateral, after maturity", async () => {
        //given
        const quote = BigNumber.from("161").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_160_18DEC
        );
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPayoff = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPayoffWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
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
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
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

    it("should close single pay fixed position using function with array, DAI", async () => {
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("1"),
            async (contract) => {
                return contract.closeSwaps([1], []);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close two pay fixed position using function with array, DAI", async () => {
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("2"),
            async (contract) => {
                return contract.closeSwaps([1, 2], []);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close single receive fixed position using function with array, DAI", async () => {
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("1"),
            async (contract) => {
                return contract.closeSwaps([], [1]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close two receive fixed position using function with array, DAI", async () => {
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("2"),
            async (contract) => {
                return contract.closeSwaps([], [1, 2]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close position by owner, pay fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [ZERO],
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            LEVERAGE_1000_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("1"),
            async (contract) => {
                return contract.emergencyCloseSwapsPayFixed([1]);
            },
            ZERO,
            true,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close position by owner, pay fixed, single id emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [ZERO],
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            LEVERAGE_1000_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            admin,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("1"),
            async (contract) => {
                return contract.emergencyCloseSwapPayFixed(1);
            },
            ZERO,
            true,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close position by owner, receive fixed, single id emergency function, DAI, when contract is paused", async () => {
        const acceptableFixedInterestRate = ZERO;
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [ZERO],
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            LEVERAGE_1000_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            acceptableFixedInterestRate,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("1"),
            async (contract) => {
                return contract.emergencyCloseSwapReceiveFixed(BigNumber.from("1"));
            },
            ZERO,
            true,
            admin,
            userOne,
            liquidityProvider
        );
    });
    it("should close only one position - close first position", async () => {
        //given
        const quote = BigNumber.from("4").mul(N0__01_18DEC);
        const acceptableFixedInterestRate = quote;
        await miltonSpreadModel.setCalculateQuotePayFixed(quote);

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

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParamsFirst = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: acceptableFixedInterestRate,
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC.add(USD_28_000_18DEC),
                derivativeParamsFirst.openTimestamp
            );
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: acceptableFixedInterestRate,
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);
        const endTimestamp = openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS);
        const expectedOpenedPositionsVol = 1;
        const expectedDerivativeId = BigNumber.from(2);

        //when
        await miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        //then
        const actualDerivatives = await miltonStorageDai.getSwapsPayFixed(
            await derivativeParams25days.from.getAddress(),
            0,
            50
        );
        const actualOpenedPositionsVol = countOpenSwaps(actualDerivatives);

        expect(
            expectedOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`
        ).to.be.eq(actualOpenedPositionsVol);

        const oneDerivative = actualDerivatives.swaps[0];

        expect(
            expectedDerivativeId,
            `Incorrect swap id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`
        ).to.be.eq(BigNumber.from(oneDerivative.id));
    });

    it("should close only one position - close last position", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
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

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParamsFirst = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC.add(USD_28_000_18DEC),
                derivativeParamsFirst.openTimestamp
            );
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);
        const endTimestamp = openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS);
        const expectedOpenedPositionsVol = 1;
        const expectedDerivativeId = BigNumber.from(1);

        //when
        await miltonDai.connect(closerUser).itfCloseSwapPayFixed(2, endTimestamp);

        //then
        const actualDerivatives = await miltonStorageDai.getSwapsPayFixed(
            await derivativeParams25days.from.getAddress(),
            0,
            50
        );
        const actualOpenedPositionsVol = countOpenSwaps(actualDerivatives);

        expect(
            expectedOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`
        ).to.be.eq(actualOpenedPositionsVol);

        const oneDerivative = actualDerivatives.swaps[0];

        expect(
            expectedDerivativeId,
            `Incorrect swap id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`
        ).to.be.eq(BigNumber.from(oneDerivative.id));
    });

    it("should close position with appropriate balance, DAI, owner, pay fixed, Milton lost, User earned < Collateral, after maturity, IPOR index calculated before close", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
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

        const expectedIncomeFeeValue = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedPayoff = SPECIFIC_INTEREST_AMOUNT_CASE_1;
        const leverage = USD_10_18DEC;
        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_5_18DEC;
        const iporValueAfterOpenSwap = PERCENTAGE_50_18DEC;
        const periodOfTimeElapsedInSeconds = PERIOD_50_DAYS_IN_SECONDS;
        const expectedOpenedPositions = ZERO;
        const expectedDerivativesTotalBalanceWad = ZERO;
        const expectedTreasuryTotalBalanceWad = expectedIncomeFeeValue;
        const expectedSoap = ZERO;

        const miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;

        const closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        const openerUserLost = TC_OPENING_FEE_18DEC.add(TC_IPOR_PUBLICATION_AMOUNT_18DEC)
            .add(TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC)
            .sub(expectedPayoff)
            .add(expectedIncomeFeeValue);

        let closerUserLost;
        let openerUserEarned;

        if ((await openerUser.getAddress()) === (await closerUser.getAddress())) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        const expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayoutWad
            .add(TC_OPENING_FEE_18DEC)
            .add(TC_IPOR_PUBLICATION_AMOUNT_18DEC)
            .sub(expectedPayoff)
            .add(expectedIncomeFeeValue);

        const expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC.add(openerUserEarned).sub(openerUserLost);
        const expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC.add(closerUserEarned).sub(closerUserLost);

        const expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad
            .sub(expectedPayoff)
            .add(TC_OPENING_FEE_18DEC);

        //given
        const localOpenTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: leverage,
            openTimestamp: localOpenTimestamp,
            from: openerUser,
        };

        if (miltonBalanceBeforePayoutWad != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);
        }

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueBeforeOpenSwap, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        const endTimestamp = params.openTimestamp.add(periodOfTimeElapsedInSeconds);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueAfterOpenSwap, params.openTimestamp);

        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                iporValueAfterOpenSwap,
                endTimestamp.sub(BigNumber.from("1"))
            );

        //additional check for position value and for incomeFee value
        const actualPayoff = await miltonDai
            .connect(params.from)
            .itfCalculateSwapPayFixedValue(endTimestamp, 1);

        const actualIncomeFeeValue = await miltonDai
            .connect(params.from)
            .itfCalculateIncomeFeeValue(actualPayoff);

        expect(actualPayoff, "Incorrect position value").to.be.eq(expectedPayoff);
        expect(actualIncomeFeeValue, "Incorrect income fee value").to.be.eq(expectedIncomeFeeValue);

        //when
        await miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            LEG_PAY_FIXED,
            openerUser,
            closerUser,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterClose,
            expectedCloserUserUnderlyingTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalanceWad,
            expectedOpenedPositions,
            expectedDerivativesTotalBalanceWad,
            expectedTreasuryTotalBalanceWad
        );

        const soapParams = {
            asset: params.asset,
            calculateTimestamp: endTimestamp,
            expectedSoap: expectedSoap,
            from: openerUser,
        };
        await assertSoap(testData, soapParams);
    });

    it("should close position by owner, receive fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [ZERO],
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            LEVERAGE_1000_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            admin,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("1"),
            async (contract) => {
                return contract.emergencyCloseSwapsReceiveFixed([1]);
            },
            ZERO,
            true,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should transfer all liquidation deposits in single transfer to liquidator - pay fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai, josephDai, miltonDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            miltonDai
                .connect(userThree)
                .itfCloseSwaps([1, 2], [], params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS))
        )
            .to.emit(tokenDai, "Transfer")
            .withArgs(
                miltonDai.address,
                await userThree.getAddress(),
                BigNumber.from("40").mul(N1__0_18DEC)
            );
    });

    it("should transfer all liquidation deposits in single transfer to liquidator - receive fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai, josephDai, miltonDai, iporOracle } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            miltonDai
                .connect(userThree)
                .itfCloseSwaps([], [1, 2], params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS))
        )
            .to.emit(tokenDai, "Transfer")
            .withArgs(
                miltonDai.address,
                await userThree.getAddress(),
                BigNumber.from("40").mul(N1__0_18DEC)
            );
    });

    it("should close two receive fixed position using function with array when one of is is not valid, DAI", async () => {
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(
            BigNumber.from("4").mul(N0__01_18DEC)
        );
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

        await executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_RECEIVE_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("2"),
            (contract) => {
                return contract.closeSwaps([], [1, 300]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close two pay fixed position using function with array when one of is is not valid, DAI", async () => {
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        executeCloseSwapsTestCase(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            LEG_PAY_FIXED,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_1_000_000_18DEC,
            BigNumber.from("2"),
            (contract) => {
                return contract.closeSwaps([1, 300], []);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close 10 pay fixed, 10 receive fixed positions in one transaction - case 1, all are opened", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const expectedSwapStatus = 0;

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        //when
        await miltonDai
            .connect(paramsPayFixed.from)
            .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        for (let i = 0; i < volumePayFixed; i++) {
            const swapPayFixed = await miltonStorageDai.getSwapPayFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapPayFixed.state
            );
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            const swapReceiveFixed = await miltonStorageDai.getSwapReceiveFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapReceiveFixed.state
            );
        }
    });

    it("should close 5 pay fixed, 5 receive fixed positions in one transaction - case 2, some of them are already closed", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 5;
        const volumeReceiveFixed = 5;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const expectedSwapStatus = 0;

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        await miltonDai.connect(paramsPayFixed.from).itfCloseSwapPayFixed(3, closeTimestamp);
        await miltonDai.connect(paramsPayFixed.from).itfCloseSwapReceiveFixed(8, closeTimestamp);

        //when
        await miltonDai
            .connect(paramsPayFixed.from)
            .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        for (let i = 0; i < volumePayFixed; i++) {
            const swapPayFixed = await miltonStorageDai.getSwapPayFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapPayFixed.state
            );
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            const swapReceiveFixed = await miltonStorageDai.getSwapReceiveFixed(i + 1);
            expect(expectedSwapStatus, `Incorrect swap status for swapId=${i + 1}`).to.be.eq(
                swapReceiveFixed.state
            );
        }
    });

    it("should close 5 pay fixed, 5 receive fixed positions in one transaction - case 3, some of them are already closed, call static", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 5;
        const volumeReceiveFixed = 5;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        await miltonDai.connect(paramsPayFixed.from).itfCloseSwapPayFixed(3, closeTimestamp);
        await miltonDai.connect(paramsPayFixed.from).itfCloseSwapReceiveFixed(8, closeTimestamp);

        //when
        const results = await miltonDai
            .connect(paramsPayFixed.from)
            .callStatic.itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        expect(true, `Incorrect is closed status`).to.be.eq(results.closedPayFixedSwaps[0].closed);
        expect(true, `Incorrect is closed status`).to.be.eq(results.closedPayFixedSwaps[1].closed);
        expect(false, `Incorrect is closed status`).to.be.eq(results.closedPayFixedSwaps[2].closed);
        expect(true, `Incorrect is closed status`).to.be.eq(results.closedPayFixedSwaps[3].closed);
        expect(true, `Incorrect is closed status`).to.be.eq(results.closedPayFixedSwaps[4].closed);
        expect(true, `Incorrect is closed status`).to.be.eq(
            results.closedReceiveFixedSwaps[0].closed
        );
        expect(true, `Incorrect is closed status`).to.be.eq(
            results.closedReceiveFixedSwaps[1].closed
        );
        expect(false, `Incorrect is closed status`).to.be.eq(
            results.closedReceiveFixedSwaps[2].closed
        );
        expect(true, `Incorrect is closed status`).to.be.eq(
            results.closedReceiveFixedSwaps[3].closed
        );
        expect(true, `Incorrect is closed status`).to.be.eq(
            results.closedReceiveFixedSwaps[4].closed
        );
    });

    it("should close 2 pay fixed, 2 receive fixed positions in one transaction - case 4, mixed liquidators, owner and not an owner", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(4);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        await openSwapPayFixed(testData, paramsPayFixed);
        await openSwapReceiveFixed(testData, paramsReceiveFixed);

        paramsPayFixed.from = userThree;
        paramsReceiveFixed.from = userThree;

        await openSwapPayFixed(testData, paramsPayFixed);
        await openSwapReceiveFixed(testData, paramsReceiveFixed);

        const swapIdsPayFixed = [1, 3];
        const swapIdsReceiveFixed = [2, 4];

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        const expectedBalanceUserTwo = BigNumber.from("9999704642032047919907479");
        const expectedBalanceUserThree = BigNumber.from("9999784642032047919907479");

        //when
        await miltonDai
            .connect(paramsPayFixed.from)
            .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const swapPayFixedOne = await miltonStorageDai.getSwapPayFixed(1);
        const swapReceiveFixedTwo = await miltonStorageDai.getSwapReceiveFixed(2);
        const swapPayFixedThree = await miltonStorageDai.getSwapPayFixed(3);
        const swapReceiveFixedFour = await miltonStorageDai.getSwapReceiveFixed(4);

        expect(0, `Incorrect is closed status`).to.be.eq(swapPayFixedOne.state);
        expect(0, `Incorrect is closed status`).to.be.eq(swapReceiveFixedTwo.state);
        expect(0, `Incorrect is closed status`).to.be.eq(swapPayFixedThree.state);
        expect(0, `Incorrect is closed status`).to.be.eq(swapReceiveFixedFour.state);

        const actualBalanceUserTwo = await tokenDai.balanceOf(await userTwo.getAddress());
        expect(expectedBalanceUserTwo, `Incorrect UserTwo balance`).to.be.eq(actualBalanceUserTwo);

        const actualBalanceUserThree = await tokenDai.balanceOf(await userThree.getAddress());
        expect(expectedBalanceUserThree, `Incorrect UserThree balance`).to.be.eq(
            actualBalanceUserThree
        );
    });

    it("should close 2 pay fixed, 2 receive fixed positions in one transaction - case 5, mixed liquidators, owner and not an owner, call static", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(4);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        await openSwapPayFixed(testData, paramsPayFixed);
        await openSwapReceiveFixed(testData, paramsReceiveFixed);

        paramsPayFixed.from = userThree;
        paramsReceiveFixed.from = userThree;

        await openSwapPayFixed(testData, paramsPayFixed);
        await openSwapReceiveFixed(testData, paramsReceiveFixed);

        const swapIdsPayFixed = [1, 3];
        const swapIdsReceiveFixed = [2, 4];

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        //when
        const results = await miltonDai
            .connect(paramsPayFixed.from)
            .callStatic.itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        expect(true, `Incorrect is closed status`).to.be.eq(results.closedPayFixedSwaps[0].closed);
        expect(true, `Incorrect is closed status`).to.be.eq(results.closedPayFixedSwaps[1].closed);
        expect(true, `Incorrect is closed status`).to.be.eq(
            results.closedReceiveFixedSwaps[0].closed
        );
        expect(true, `Incorrect is closed status`).to.be.eq(
            results.closedReceiveFixedSwaps[1].closed
        );
    });

    it("should close 2 pay fixed, 2 receive fixed positions in one transaction - case 5, mixed liquidators, owner and not an owner, less than 28 days", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(4);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        await openSwapPayFixed(testData, paramsPayFixed);
        await openSwapReceiveFixed(testData, paramsReceiveFixed);

        paramsPayFixed.from = userThree;
        paramsReceiveFixed.from = userThree;

        await openSwapPayFixed(testData, paramsPayFixed);
        await openSwapReceiveFixed(testData, paramsReceiveFixed);

        const swapIdsPayFixed = [1, 3];
        const swapIdsReceiveFixed = [2, 4];

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        //when
        await assertError(
            miltonDai
                .connect(paramsPayFixed.from)
                .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp),
            "IPOR_321"
        );
    });

    it("should NOT close 12 pay fixed, 2 receive fixed positions in one transaction - Liquidation Leg Limit exceeded", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 12;
        const volumeReceiveFixed = 2;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        //when
        await assertError(
            miltonDai
                .connect(paramsPayFixed.from)
                .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp),
            "IPOR_315"
        );
    });

    it("should NOT close 2 pay fixed, 12 receive fixed positions in one transaction - Liquidation Leg Limit exceeded", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 2;
        const volumeReceiveFixed = 12;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        //when
        await assertError(
            miltonDai
                .connect(paramsPayFixed.from)
                .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp),
            "IPOR_315"
        );
    });

    it("should close 10 pay fixed, 10 receive fixed positions in one transaction - verify balances", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        const totalLiquidationDepositAmount = N1__0_18DEC.mul(
            20 * (volumePayFixed + volumeReceiveFixed)
        );

        const expectedBalanceTrader = BigNumber.from("9997046420320479199074790");
        const expectedBalanceLiquidator = USER_SUPPLY_10MLN_18DEC.add(
            totalLiquidationDepositAmount
        );

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidator = await tokenDai.balanceOf(await userThree.getAddress());
        expect(expectedBalanceLiquidator, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidator
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("should close 2 pay fixed, 0 receive fixed positions in one transaction - all receive fixed positions already closed", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;
        const liquidationDepositAmount = 20;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        const expectedBalanceTrader = BigNumber.from("9997046420320479199074790").add(
            N1__0_18DEC.mul(liquidationDepositAmount * volumePayFixed)
        );
        const expectedBalanceLiquidator = USER_SUPPLY_10MLN_18DEC.add(
            N1__0_18DEC.mul(liquidationDepositAmount * volumeReceiveFixed)
        );

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await miltonDai
                .connect(paramsReceiveFixed.from)
                .itfCloseSwapReceiveFixed(i + 1, closeTimestamp);
        }

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidator = await tokenDai.balanceOf(await userThree.getAddress());
        expect(expectedBalanceLiquidator, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidator
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("should close 0 pay fixed, 2 receive fixed positions in one transaction - all pay fixed positions already closed", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 10;
        const volumeReceiveFixed = 10;
        const liquidationDepositAmount = 20;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        const expectedBalanceTrader = BigNumber.from("9997046420320479199074790").add(
            N1__0_18DEC.mul(liquidationDepositAmount * volumeReceiveFixed)
        );
        const expectedBalanceLiquidator = USER_SUPPLY_10MLN_18DEC.add(
            N1__0_18DEC.mul(liquidationDepositAmount * volumePayFixed)
        );

        for (let i = 0; i < volumePayFixed; i++) {
            await miltonDai
                .connect(paramsPayFixed.from)
                .itfCloseSwapPayFixed(i + 1, closeTimestamp);
        }

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidator = await tokenDai.balanceOf(await userThree.getAddress());
        expect(expectedBalanceLiquidator, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidator
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("[!] should commit transaction try to close 2 pay fixed, 2 receive fixed positions in one transaction - all positions already closed", async () => {
        //given
        await miltonSpreadModel.setCalculateQuoteReceiveFixed(
            BigNumber.from("4").mul(N0__01_18DEC)
        );
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
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

        const paramsPayFixed = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const paramsReceiveFixed = getReceiveFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        paramsReceiveFixed.from = paramsPayFixed.from;
        paramsReceiveFixed.openTimestamp = paramsPayFixed.openTimestamp;

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsPayFixed.asset, PERCENTAGE_3_18DEC, paramsPayFixed.openTimestamp);

        const volumePayFixed = 2;
        const volumeReceiveFixed = 2;

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC.mul(
            volumePayFixed + volumeReceiveFixed
        );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, paramsPayFixed.openTimestamp);

        const swapIdsPayFixed = [];
        const swapIdsReceiveFixed = [];
        const liquidationDepositAmount = 20;

        for (let i = 0; i < volumePayFixed; i++) {
            await openSwapPayFixed(testData, paramsPayFixed);
            swapIdsPayFixed.push(i + 1);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await openSwapReceiveFixed(testData, paramsReceiveFixed);
            swapIdsReceiveFixed.push(i + 1);
        }

        const closeTimestamp = paramsPayFixed.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);

        for (let i = 0; i < volumePayFixed; i++) {
            await miltonDai
                .connect(paramsPayFixed.from)
                .itfCloseSwapPayFixed(i + 1, closeTimestamp);
        }

        for (let i = volumePayFixed; i < volumePayFixed + volumeReceiveFixed; i++) {
            await miltonDai
                .connect(paramsReceiveFixed.from)
                .itfCloseSwapReceiveFixed(i + 1, closeTimestamp);
        }

        const expectedBalanceTrader = BigNumber.from("9999489284064095839814958");

        const actualBalanceLiquidatorBefore = await tokenDai.balanceOf(
            await userThree.getAddress()
        );

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwaps(swapIdsPayFixed, swapIdsReceiveFixed, closeTimestamp);

        //then
        const actualBalanceLiquidatorAfter = await tokenDai.balanceOf(await userThree.getAddress());
        expect(actualBalanceLiquidatorBefore, `Incorrect liquidator balance`).to.be.eq(
            actualBalanceLiquidatorAfter
        );

        const actualBalanceTrader = await tokenDai.balanceOf(
            await paramsPayFixed.from.getAddress()
        );
        expect(expectedBalanceTrader, `Incorrect trader balance`).to.be.eq(actualBalanceTrader);
    });

    it("should commit transaction even if lists for closing are empty", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { miltonDai } = testData;
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const closeTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        //when
        const result = await miltonDai.connect(userThree).itfCloseSwaps([], [], closeTimestamp);

        //then
        // no errors during execution closeSwaps.
    });

    it("should close position, DAI, when amount exceeds balance milton on DAI token", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("6").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_5_18DEC
        );

        const { tokenDai, josephDai, iporOracle, miltonDai, stanleyDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined || stanleyDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const initStanleyBalance = BigNumber.from("30000").mul(N1__0_18DEC);
        await tokenDai.approve(stanleyDai.address, USD_1_000_000_18DEC);
        await stanleyDai.testDeposit(miltonDai.address, initStanleyBalance);

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        await hre.network.provider.send("hardhat_setBalance", [
            miltonDai.address,
            "0x500000000000000000000",
        ]);
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [miltonDai.address],
        });
        const signer = await hre.ethers.provider.getSigner(miltonDai.address);
        const daiBalanceAfterOpen = await tokenDai.balanceOf(miltonDai.address);
        await tokenDai.connect(signer).transfer(await admin.getAddress(), daiBalanceAfterOpen);

        const userTwoBalanceBefore = await tokenDai.balanceOf(await userTwo.getAddress());
        const stanleyBalanceBefore = await tokenDai.balanceOf(stanleyDai.address);
        const miltonBalanceBefore = await tokenDai.balanceOf(miltonDai.address);

        //when
        await miltonDai.connect(userTwo).itfCloseSwapPayFixed(1, endTimestamp);

        //then

        const userTwoBalanceAfter = await tokenDai.balanceOf(await userTwo.getAddress());
        const stanleyBalanceAfter = await tokenDai.balanceOf(stanleyDai.address);
        const miltonBalanceAfter = await tokenDai.balanceOf(miltonDai.address);

        expect(userTwoBalanceBefore).to.be.equal(BigNumber.from("9990000").mul(N1__0_18DEC));
        expect(userTwoBalanceAfter).to.be.equal(BigNumber.from("10007750013530187519076909"));
        expect(stanleyBalanceBefore).to.be.equal(initStanleyBalance);
        expect(stanleyBalanceAfter.lt(stanleyBalanceBefore)).to.be.true;
        expect(miltonBalanceBefore).to.be.equal(ZERO);
        expect(miltonBalanceAfter.gt(ZERO)).to.be.true;
    });
});
