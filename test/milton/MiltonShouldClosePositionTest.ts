import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    ZERO,
    USD_10_18DEC,
    USD_28_000_18DEC,
    USD_50_000_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_365_18DEC,
    PERCENTAGE_366_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    N0__1_18DEC,
    N1__0_18DEC,
    TC_OPENING_FEE_18DEC,
    TC_COLLATERAL_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    PERCENTAGE_4_18DEC,
    USD_20_18DEC,
    USER_SUPPLY_10MLN_18DEC,
    TC_INCOME_TAX_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_161_18DEC,
    PERCENTAGE_5_18DEC,
    TC_COLLATERAL_6DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_121_18DEC,
    PERIOD_50_DAYS_IN_SECONDS,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_50_18DEC,
    SPECIFIC_INTEREST_AMOUNT_CASE_1,
    SPECIFIC_INCOME_TAX_CASE_1,
    PERCENTAGE_151_18DEC,
    PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
    PERCENTAGE_150_18DEC,
    PERCENTAGE_149_18DEC,
    USD_10_000_000_18DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_28_DAYS_IN_SECONDS,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    testCaseWhenMiltonEarnAndUserLost,
    testCaseWhenMiltonLostAndUserEarn,
} from "../utils/MiltonUtils";
import {
    openSwapPayFixed,
    exetuceCloseSwapTestCase,
    executeCloseSwapsTestCase,
    countOpenSwaps,
    assertSoap,
} from "../utils/SwapUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import {
    prepareComplexTestDataDaiCase000,
    getPayFixedDerivativeParamsDAICase1,
    prepareApproveForUsers,
    prepareTestData,
    setupTokenUsdtInitialValuesForUsers,
    setupTokenDaiInitialValuesForUsers,
} from "../utils/DataUtils";
import { assertError, assertExpectedValues } from "../utils/AssertUtils";

const { expect } = chai;

describe("Milton - close position", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        const liquidationDepositAmount = USD_20_18DEC;

        const expectedIncomeFeeValue = ZERO;
        const expectedIncomeFeeValueWad = ZERO;

        const totalAmount = TC_TOTAL_AMOUNT_10_000_18DEC;
        const collateral = TC_COLLATERAL_18DEC;
        const openingFee = TC_OPENING_FEE_18DEC;

        const diffAfterClose = totalAmount.sub(collateral).sub(liquidationDepositAmount);

        const expectedOpenerUserUnderlyingTokenBalanceAfterPayOut =
            USER_SUPPLY_10MLN_18DEC.sub(diffAfterClose);
        const expectedCloserUserUnderlyingTokenBalanceAfterPayOut =
            USER_SUPPLY_10MLN_18DEC.sub(diffAfterClose);

        const expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad.add(diffAfterClose);
        const expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad
            .add(openingFee)
            .sub(expectedIncomeFeeValue);

        const expectedPositionValue = ZERO;

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await exetuceCloseSwapTestCase(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_4_18DEC,
            ZERO,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
            expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalanceWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            ZERO,
            ZERO,
            expectedPositionValue,
            expectedIncomeFeeValue,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const expectedIncomeFeeValueWad = BigNumber.from("6826719107555404611");
        const expectedPositionValue = BigNumber.from("-68267191075554046114");
        const expectedPositionValueWad = BigNumber.from("-68267191075554046114");

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_366_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it.skip("should close position, USDT, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, USDT 6 decimals", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
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

        const expectedIncomeFeeValueWad = BigNumber.from("6826719107555404611");
        const expectedPositionValue = BigNumber.from("-68267191");
        const expectedPositionValueWad = BigNumber.from("-68267191075554046114");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_366_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > totalAmount, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it.skip("should close position, USDT, owner, pay fixed, Milton earned, User lost > totalAmount, before maturity, USDT 6 decimals", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
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
        const expectedPositionValue = TC_COLLATERAL_6DEC.mul("-1");
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul("-1");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("791899416476426938347");
        const expectedPositionValue = BigNumber.from("-7918994164764269383465");
        const expectedPositionValueWad = BigNumber.from("-7918994164764269383465");
        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it.skip("should close position, USDT, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
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

        const expectedIncomeFeeValueWad = BigNumber.from("791899416476426938347");
        const expectedPositionValue = BigNumber.from("-7918994165");
        const expectedPositionValueWad = BigNumber.from("-7918994164764269383465");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("996700989703089073278");
        const expectedPositionValue = BigNumber.from("-9967009897030890732780");
        const expectedPositionValueWad = BigNumber.from("-9967009897030890732780");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, USDT 6 decimals", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
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
        const expectedPositionValue = TC_COLLATERAL_6DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("778245978261316123526");
        const expectedIncomeFeeValueWad = BigNumber.from("778245978261316123526");

        const expectedPositionValue = BigNumber.from("7782459782613161235257");
        const expectedPositionValueWad = BigNumber.from("7782459782613161235257");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, USDT 6 decimals", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
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

        const expectedIncomeFeeValue = BigNumber.from("778245978");
        const expectedIncomeFeeValueWad = BigNumber.from("778245978261316123526");
        const expectedPositionValue = BigNumber.from("7782459782");
        const expectedPositionValueWad = BigNumber.from("7782459782613161235257");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedIncomeFeeValueWad = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedPositionValue = SPECIFIC_INTEREST_AMOUNT_CASE_1;
        const expectedPositionValueWad = SPECIFIC_INTEREST_AMOUNT_CASE_1;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, 100% Deposit > User earned > 99% Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("989874270595533665253");
        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533665253");
        const expectedPositionValue = BigNumber.from("9898742705955336652531");
        const expectedPositionValueWad = BigNumber.from("9898742705955336652531");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_151_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Deposit, 5 hours before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("865150112500496428963");
        const expectedIncomeTaxValueWad = BigNumber.from("865150112500496428963");
        const expectedPositionValue = BigNumber.from("8651501125004964289632");
        const expectedPositionValueWad = BigNumber.from("8651501125004964289632");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedIncomeFeeValueWad = SPECIFIC_INCOME_TAX_CASE_1;
        const expectedPositionValue = SPECIFIC_INTEREST_AMOUNT_CASE_1;
        const expectedPositionValueWad = SPECIFIC_INTEREST_AMOUNT_CASE_1;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, 100% Deposit > User lost > 99% Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("989874270595533672762");
        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533672762");
        const expectedPositionValue = BigNumber.from("-9898742705955336727624");
        const expectedPositionValueWad = BigNumber.from("-9898742705955336727624");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_150_18DEC,
            PERCENTAGE_6_18DEC,
            PERCENTAGE_151_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("996700989703089073278");
        const expectedIncomeFeeValueWad = BigNumber.from("996700989703089073278");
        const expectedPositionValue = BigNumber.from("-9967009897030890732780");
        const expectedPositionValueWad = BigNumber.from("-9967009897030890732780");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, 5 hours before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("880328184649627945216");
        const expectedIncomeTaxValueWad = BigNumber.from("880328184649627945216");
        const expectedPositionValue = BigNumber.from("-8803281846496279452160");
        const expectedPositionValueWad = BigNumber.from("-8803281846496279452160");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price not changed, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("6826719107555402563");
        const expectedIncomeFeeValueWad = BigNumber.from("6826719107555402563");
        const expectedPositionValue = BigNumber.from("-68267191075554025634");
        const expectedPositionValueWad = BigNumber.from("-68267191075554025634");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_3_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price changed 25%, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = BigNumber.from("6826719107555404611");
        const expectedPositionValue = BigNumber.from("-68267191075554046114");
        const expectedPositionValueWad = BigNumber.from("-68267191075554046114");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("279895483409771589481");
        const expectedIncomeFeeValueWad = BigNumber.from("279895483409771589481");
        const expectedPositionValue = BigNumber.from("-2798954834097715894807");
        const expectedPositionValueWad = BigNumber.from("-2798954834097715894807");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("791899416476426932749");
        const expectedIncomeFeeValueWad = BigNumber.from("791899416476426932749");
        const expectedPositionValue = BigNumber.from("-7918994164764269327486");
        const expectedPositionValueWad = BigNumber.from("-7918994164764269327486");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("996700989703089073278");
        const expectedIncomeFeeValueWad = BigNumber.from("996700989703089073278");
        const expectedPositionValue = BigNumber.from("9967009897030890732780");
        const expectedPositionValueWad = BigNumber.from("9967009897030890732780");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedIncomeFeeValueWad = BigNumber.from("628058157895097225759");
        const expectedPositionValue = BigNumber.from("-6280581578950972257591");
        const expectedPositionValueWad = BigNumber.from("-6280581578950972257591");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, 100% Deposit > User earned > 99% Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("989874270595533672080");
        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533672080");
        const expectedPositionValue = BigNumber.from("9898742705955336720799");
        const expectedPositionValueWad = BigNumber.from("9898742705955336720799");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_151_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_151_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, 100% Deposit > User lost > 99% Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeTaxValue = BigNumber.from("989874270595533666618");
        const expectedIncomeTaxValueWad = BigNumber.from("989874270595533666618");
        const expectedPositionValue = BigNumber.from("-9898742705955336666184");
        const expectedPositionValueWad = BigNumber.from("-9898742705955336666184");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_149_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC;
        const expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("996700989703089073278");
        const expectedIncomeFeeValueWad = BigNumber.from("996700989703089073278");
        const expectedPositionValue = BigNumber.from("9967009897030890732780");
        const expectedPositionValueWad = BigNumber.from("9967009897030890732780");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("628058157895097225759");
        const expectedIncomeFeeValueWad = BigNumber.from("628058157895097225759");
        const expectedPositionValue = BigNumber.from("-6280581578950972257591");
        const expectedPositionValueWad = BigNumber.from("-6280581578950972257591");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const { tokenDai } = testData;
        if (tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        const expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        const expectedPositionValue = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));
        const expectedPositionValueWad = TC_COLLATERAL_18DEC.mul(BigNumber.from("-1"));

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    it("should calculate Pay Fixed Position Value - simple case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
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

        const expectedPositionValue = BigNumber.from("-38229627002310297226");

        //when
        const actualPositionValue = BigNumber.from(
            await miltonDai.itfCalculateSwapPayFixedValue(
                params.openTimestamp.add(PERIOD_14_DAYS_IN_SECONDS),
                derivativeItem.id
            )
        );

        //then
        expect(
            expectedPositionValue,
            `Incorrect position value, actual: ${actualPositionValue}, expected: ${expectedPositionValue}`
        ).to.be.eq(actualPositionValue);
    });

    it("should fail to close pay fixed positions using multicall function when list of swaps is empty, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                ZERO,
                (contract) => {
                    return contract.closeSwapsPayFixed([]);
                },
                ZERO,
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "IPOR_315"
        );
    });

    it("should close single pay fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.closeSwapsPayFixed([1]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close two pay fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("2"),
            (contract) => {
                return contract.closeSwapsPayFixed([1, 2]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should fail to close receive fixed positions using multicall function when list of swaps is empty, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

        await assertError(
            executeCloseSwapsTestCase(
                testData,
                tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                ZERO,
                (contract) => {
                    return contract.closeSwapsReceiveFixed([]);
                },
                ZERO,
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "IPOR_315"
        );
    });

    it("should close single receive fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.closeSwapsReceiveFixed([1]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close two receive fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("2"),
            (contract) => {
                return contract.closeSwapsReceiveFixed([1, 2]);
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
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            0,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
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
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            0,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.emergencyCloseSwapPayFixed(1);
            },
            ZERO,
            true,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close position by owner, receive fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            1,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.emergencyCloseSwapsReceiveFixed([1]);
            },
            ZERO,
            true,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close position by owner, receive fixed, single id emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            1,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.emergencyCloseSwapReceiveFixed(1);
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
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
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
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
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
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
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
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
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
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
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
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
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

    it("should close position with appropriate balance, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity, IPOR index calculated before close", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
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
        const expectedPositionValue = SPECIFIC_INTEREST_AMOUNT_CASE_1;
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
        const openTimestamp = null;

        const miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;

        const closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        const openerUserLost = TC_OPENING_FEE_18DEC.add(TC_IPOR_PUBLICATION_AMOUNT_18DEC)
            .add(TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC)
            .sub(expectedPositionValue)
            .add(expectedIncomeFeeValue);

        let closerUserLost = null;
        let openerUserEarned = null;

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
            .sub(expectedPositionValue)
            .add(expectedIncomeFeeValue);

        const expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC.add(openerUserEarned).sub(openerUserLost);
        const expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC.add(closerUserEarned).sub(closerUserLost);

        const expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad
            .sub(expectedPositionValue)
            .add(TC_OPENING_FEE_18DEC);

        //given
        let localOpenTimestamp = ZERO;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        }
        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
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
        const actualPositionValue = await miltonDai
            .connect(params.from)
            .itfCalculateSwapPayFixedValue(endTimestamp, 1);

        const actualIncomeFeeValue = await miltonDai
            .connect(params.from)
            .itfCalculateIncomeFeeValue(actualPositionValue);

        expect(actualPositionValue, "Incorrect position value").to.be.eq(expectedPositionValue);
        expect(actualIncomeFeeValue, "Incorrect income fee value").to.be.eq(expectedIncomeFeeValue);

        //when
        await miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            0,
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

    it("should close single pay fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.closeSwapsPayFixed([1]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close two pay fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("2"),
            (contract) => {
                return contract.closeSwapsPayFixed([1, 2]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close single receive fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.closeSwapsReceiveFixed([1]);
            },
            ZERO,
            false,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close two receive fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("2"),
            (contract) => {
                return contract.closeSwapsReceiveFixed([1, 2]);
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
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            0,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
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
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            0,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.emergencyCloseSwapPayFixed(1);
            },
            ZERO,
            true,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close position by owner, receive fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            1,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.emergencyCloseSwapsReceiveFixed([1]);
            },
            ZERO,
            true,
            admin,
            userOne,
            liquidityProvider
        );
    });

    it("should close position by owner, receive fixed, single id emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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
            1,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            BigNumber.from("1"),
            (contract) => {
                return contract.emergencyCloseSwapReceiveFixed(1);
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
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
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
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            miltonDai
                .connect(userThree)
                .itfCloseSwapsPayFixed([1, 2], params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS))
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
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
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
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_160_18DEC, params.openTimestamp);

        await expect(
            miltonDai
                .connect(userThree)
                .itfCloseSwapsReceiveFixed([1, 2], params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS))
        )
            .to.emit(tokenDai, "Transfer")
            .withArgs(
                miltonDai.address,
                await userThree.getAddress(),
                BigNumber.from("40").mul(N1__0_18DEC)
            );
    });
});
