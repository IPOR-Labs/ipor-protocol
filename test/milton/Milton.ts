import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N0__01_18DEC,
    N1__0_18DEC,
    USD_28_000_6DEC,
    USD_10_000_18DEC,
    ZERO,
    USD_10_18DEC,
    USD_28_000_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_365_18DEC,
    PERCENTAGE_366_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    LEVERAGE_18DEC,
    N0__1_18DEC,
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
    PERIOD_27_DAYS_17_HOURS_IN_SECONDS,
    PERCENTAGE_150_18DEC,
    PERCENTAGE_149_18DEC,
    PERCENTAGE_119_18DEC,
    USD_10_000_000_18DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    PERIOD_14_DAYS_IN_SECONDS,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMiltonSpreadBase,
    testCaseWhenMiltonEarnAndUserLost,
    testCaseWhenMiltonLostAndUserEarn,
} from "../utils/MiltonUtils";
import {
    openSwapPayFixed,
    exetuceCloseSwapTestCase,
    openSwapReceiveFixed,
    executeCloseSwapsTestCase,
    countOpenSwaps,
    assertSoap,
} from "../utils/SwapUtiles";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import {
    prepareComplexTestDataDaiCase000,
    prepareTestDataDaiCase000,
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareApproveForUsers,
    prepareTestData,
    setupTokenUsdtInitialValuesForUsers,
    setupTokenDaiInitialValuesForUsers,
} from "../utils/DataUtils";
import {
    assertError,
    assertExpectedValues,
    assertMiltonDerivativeItem,
} from "../utils/AssertUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Core", () => {
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

    it("should NOT open position because totalAmount amount too low", async () => {
        //given
        const { miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const totalAmount = ZERO;
        const toleratedQuoteValue = BigNumber.from("3");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(timestamp, totalAmount, toleratedQuoteValue, leverage),
            //then
            "IPOR_308"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - pay fixed 18 decimals", async () => {
        //given
        const { warren, tokenDai, josephDai, miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const totalAmount = BigNumber.from("30000000000000000001");
        const toleratedQuoteValue = BigNumber.from("39999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await warren
            .connect(userOne)
            .itfUpdateIndex(tokenDai.address, PERCENTAGE_3_18DEC, timestamp);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_18DEC, timestamp);

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(timestamp, totalAmount, toleratedQuoteValue, leverage),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - receive fixed 18 decimals", async () => {
        //given
        const { warren, tokenDai, josephDai, miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const totalAmount = BigNumber.from("30000000000000000001");
        const toleratedQuoteValue = BigNumber.from("19999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await warren
            .connect(userOne)
            .itfUpdateIndex(tokenDai.address, PERCENTAGE_3_18DEC, timestamp);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_18DEC, timestamp);

        await assertError(
            //when
            miltonDai.itfOpenSwapReceiveFixed(
                timestamp,
                totalAmount,
                toleratedQuoteValue,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - pay fixed 6 decimals", async () => {
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

        const { tokenUsdt, warren, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const totalAmount = BigNumber.from("30000001");
        const toleratedQuoteValue = BigNumber.from("39999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await warren
            .connect(userOne)
            .itfUpdateIndex(tokenUsdt.address, PERCENTAGE_3_18DEC, timestamp);

        await josephUsdt.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_6DEC, timestamp);

        await assertError(
            //when
            miltonUsdt.itfOpenSwapPayFixed(timestamp, totalAmount, toleratedQuoteValue, leverage),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - receive fixed 6 decimals", async () => {
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

        const { tokenUsdt, warren, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        const totalAmount = BigNumber.from("30000001");
        const toleratedQuoteValue = BigNumber.from("19999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await warren
            .connect(userOne)
            .itfUpdateIndex(tokenUsdt.address, PERCENTAGE_3_18DEC, timestamp);

        await josephUsdt.connect(liquidityProvider).itfProvideLiquidity(USD_28_000_6DEC, timestamp);

        await assertError(
            //when
            miltonUsdt.itfOpenSwapReceiveFixed(
                timestamp,
                totalAmount,
                toleratedQuoteValue,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because totalAmount amount too high", async () => {
        //given
        const { miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const totalAmount = BigNumber.from("1000000000000000000000001");
        const toleratedQuoteValue = 3;
        const leverage = BigNumber.from("10").mul(N1__0_18DEC);
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(timestamp, totalAmount, toleratedQuoteValue, leverage),
            //then
            "IPOR_310"
        );
    });

    it("should NOT open position because totalAmount amount too high - case 2", async () => {
        //given
        const { miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const totalAmount = BigNumber.from("100688870576704582165765");
        const toleratedQuoteValue = 3;
        const leverage = BigNumber.from("10").mul(N1__0_18DEC);
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await assertError(
            //when
            miltonDai.itfOpenSwapPayFixed(timestamp, totalAmount, toleratedQuoteValue, leverage),
            //then
            "IPOR_310"
        );
    });

    it("should NOT open position because Liquidity Pool balance is to low", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, miltonDai, warren, miltonStorageDai } = testData;

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: USD_10_000_18DEC, //10 000 USD
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        const closeSwapTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, N0__01_18DEC, params.openTimestamp);

        await openSwapPayFixed(testData, params);

        await warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                BigNumber.from("16").mul(N0__1_18DEC),
                params.openTimestamp
            );

        await warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                BigNumber.from("5").mul(N0__01_18DEC),
                closeSwapTimestamp
            );

        await miltonStorageDai.setJoseph(await userOne.getAddress());

        await miltonStorageDai
            .connect(userOne)
            .subtractLiquidity(BigNumber.from("20000").mul(N1__0_18DEC));

        await miltonStorageDai.setJoseph(josephDai.address);

        //when
        await assertError(
            //when
            miltonDai.connect(userTwo).itfCloseSwapPayFixed(1, closeSwapTimestamp),
            //then
            "IPOR_319"
        );
    });

    // #######################################

    it("should open pay fixed position - simple case DAI - 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, miltonDai, warren } = testData;

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        const collateralWad = TC_COLLATERAL_18DEC;
        const openingFee = TC_OPENING_FEE_18DEC;

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC;

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);

        const expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayoutWad.add(
            params.totalAmount
        );
        const expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad.add(openingFee);
        const expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            0,
            userTwo,
            userTwo,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            BigNumber.from("9990000").mul(N1__0_18DEC),
            BigNumber.from("9990000").mul(N1__0_18DEC),
            expectedLiquidityPoolTotalBalanceWad,
            BigNumber.from("1"),
            TC_COLLATERAL_18DEC,
            ZERO
        );

        const actualPayFixDerivativesBalanceWad = BigNumber.from(
            await (
                await miltonDai.getAccruedBalance()
            ).payFixedTotalCollateral
        );
        const actualRecFixDerivativesBalanceWad = BigNumber.from(
            await (
                await miltonDai.getAccruedBalance()
            ).receiveFixedTotalCollateral
        );
        const actualDerivativesTotalBalanceWad = actualPayFixDerivativesBalanceWad.add(
            actualRecFixDerivativesBalanceWad
        );

        expect(
            expectedDerivativesTotalBalanceWad,
            `Incorrect derivatives total balance for ${params.asset} actual ${actualDerivativesTotalBalanceWad}, expected ${expectedDerivativesTotalBalanceWad}Wad`
        ).to.be.eq(actualDerivativesTotalBalanceWad);
    });

    it("should open pay fixed position - simple case USDT - 6 decimals", async () => {
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

        const { tokenUsdt, warren, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );
        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        const collateralWad = TC_COLLATERAL_18DEC;
        const openingFee = TC_OPENING_FEE_18DEC;

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const miltonBalanceBeforePayout = USD_28_000_6DEC;
        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC;

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayout, params.openTimestamp);

        const expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayout.add(
            params.totalAmount
        );
        const expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad.add(openingFee);
        const expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            0,
            userTwo,
            userTwo,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            BigNumber.from("9990000000000"),
            BigNumber.from("9990000000000"),
            expectedLiquidityPoolTotalBalanceWad,
            BigNumber.from("1"),
            TC_COLLATERAL_18DEC,
            BigNumber.from("0")
        );
        const actualPayFixDerivativesBalanceWad = BigNumber.from(
            await (
                await miltonUsdt.getAccruedBalance()
            ).payFixedTotalCollateral
        );

        const actualRecFixDerivativesBalanceWad = BigNumber.from(
            await (
                await miltonUsdt.getAccruedBalance()
            ).receiveFixedTotalCollateral
        );

        const actualDerivativesTotalBalanceWad = actualPayFixDerivativesBalanceWad.add(
            actualRecFixDerivativesBalanceWad
        );

        expect(
            expectedDerivativesTotalBalanceWad,
            `Incorrect derivatives total balance for ${params.asset} actual ${actualDerivativesTotalBalanceWad}, expected ${expectedDerivativesTotalBalanceWad}Wad`
        ).to.be.eq(actualDerivativesTotalBalanceWad);
    });

    it("should open pay fixed position, DAI, custom Opening Fee for Treasury 50%", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE4,
            MiltonUsdtCase.CASE4,
            MiltonDaiCase.CASE4,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenDai, warren, josephDai, miltonDai, miltonStorageDai } = testData;

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
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
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const expectedTreasuryTotalBalanceWad = BigNumber.from("149505148455463361");

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        const expectedLiquidityPoolTotalBalanceWad = BigNumber.from("28002840597820653803859");

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        //then
        const balance = await miltonStorageDai.getExtendedBalance();

        const actualLiquidityPoolTotalBalanceWad = BigNumber.from(balance.liquidityPool);
        const actualTreasuryTotalBalanceWad = BigNumber.from(balance.treasury);

        expect(
            expectedLiquidityPoolTotalBalanceWad,
            `Incorrect Liquidity Pool total balance for ${params.asset}, actual:  ${actualLiquidityPoolTotalBalanceWad},
            expected: ${expectedLiquidityPoolTotalBalanceWad}`
        ).to.be.eq(actualLiquidityPoolTotalBalanceWad);
        expect(
            expectedTreasuryTotalBalanceWad,
            `Incorrect Treasury total balance for ${params.asset}, actual:  ${actualTreasuryTotalBalanceWad},
            expected: ${expectedTreasuryTotalBalanceWad}`
        ).to.be.eq(actualTreasuryTotalBalanceWad);
    });

    it("should open pay fixed position, DAI, custom Opening Fee for Treasury 25%", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE5,
            MiltonUsdtCase.CASE5,
            MiltonDaiCase.CASE5,
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

        const { tokenDai, warren, josephDai, miltonDai, miltonStorageDai } = testData;

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const expectedTreasuryTotalBalanceWad = BigNumber.from("74752574227731681");

        const miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        const expectedLiquidityPoolTotalBalanceWad = BigNumber.from("28002915350394881535539");
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        //then
        const balance = await miltonStorageDai.getExtendedBalance();

        const actualLiquidityPoolTotalBalanceWad = BigNumber.from(balance.liquidityPool);
        const actualTreasuryTotalBalanceWad = BigNumber.from(balance.treasury);

        expect(
            expectedLiquidityPoolTotalBalanceWad,
            `Incorrect Liquidity Pool total balance for ${params.asset}, actual:  ${actualLiquidityPoolTotalBalanceWad},
            expected: ${expectedLiquidityPoolTotalBalanceWad}`
        ).to.be.eq(actualLiquidityPoolTotalBalanceWad);
        expect(
            expectedTreasuryTotalBalanceWad,
            `Incorrect Treasury total balance for ${params.asset}, actual:  ${actualTreasuryTotalBalanceWad},
            expected: ${expectedTreasuryTotalBalanceWad}`
        ).to.be.eq(actualTreasuryTotalBalanceWad);
    });

    it("should open pay fixed position, DAI, custom leverage - simple case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, warren, josephDai, miltonDai, miltonStorageDai } = testData;

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: BigNumber.from("15125000000000000000"),
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset.address, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        //when
        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        //then
        const actualDerivativeItem = await miltonStorageDai.getSwapPayFixed(1);
        const actualNotionalAmount = BigNumber.from(actualDerivativeItem.notionalAmount);
        const expectedNotionalAmount = BigNumber.from("150751024692592222333298");

        expect(
            expectedNotionalAmount,
            `Incorrect notional amount for ${params.asset}, actual:  ${actualNotionalAmount},
            expected: ${expectedNotionalAmount}`
        ).to.be.eq(actualNotionalAmount);
    });

    it("should open pay fixed position - when open timestamp is long time ago", async () => {
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
        const veryLongTimeAgoTimestamp = 31536000; //1971-01-01
        const expectedIncomeFeeValueWad = ZERO;
        const expectedPositionValue = ZERO;
        const expectedPositionValueWad = ZERO;

        await testCaseWhenMiltonEarnAndUserLost(
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
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            BigNumber.from(veryLongTimeAgoTimestamp),
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad,
            userOne,
            liquidityProvider
        );
    });

    // // #########################################################

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

        const expectedIncomeFeeValueWad = BigNumber.from("856889782380354383694");
        const expectedPositionValue = BigNumber.from("-8568897823803543836942");
        const expectedPositionValueWad = BigNumber.from("-8568897823803543836942");

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

        const expectedIncomeFeeValue = BigNumber.from("636796358352768143662");
        const expectedIncomeFeeValueWad = BigNumber.from("636796358352768143662");
        const expectedPositionValue = BigNumber.from("6367963583527681436620");
        const expectedPositionValueWad = BigNumber.from("6367963583527681436620");

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

        const expectedIncomeFeeValue = BigNumber.from("856889782380354383694");
        const expectedIncomeFeeValueWad = BigNumber.from("856889782380354383694");
        const expectedPositionValue = BigNumber.from("-8568897823803543836942");
        const expectedPositionValueWad = BigNumber.from("-8568897823803543836942");

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

        const expectedIncomeFeeValue = BigNumber.from("841597931579430277365");
        const expectedIncomeFeeValueWad = BigNumber.from("841597931579430277365");
        const expectedPositionValue = BigNumber.from("8415979315794302773646");
        const expectedPositionValueWad = BigNumber.from("8415979315794302773646");

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
        const expectedIncomeFeeValueWad = BigNumber.from("652088209153692249992");
        const expectedPositionValue = BigNumber.from("-6520882091536922499916");
        const expectedPositionValueWad = BigNumber.from("-6520882091536922499916");

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

        const expectedIncomeFeeValue = BigNumber.from("841597931579430277365");
        const expectedIncomeFeeValueWad = BigNumber.from("841597931579430277365");
        const expectedPositionValue = BigNumber.from("8415979315794302773646");
        const expectedPositionValueWad = BigNumber.from("8415979315794302773646");

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

        const expectedIncomeFeeValue = BigNumber.from("652088209153692249992");
        const expectedIncomeFeeValueWad = BigNumber.from("652088209153692249992");
        const expectedPositionValue = BigNumber.from("-6520882091536922499916");
        const expectedPositionValueWad = BigNumber.from("-6520882091536922499916");

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

    // // ######################################

    it("should NOT close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, 7 hours before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: PERCENTAGE_121_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("11900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, 7 hours before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("11900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_27_DAYS_17_HOURS_IN_SECONDS);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        const endTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should NOT close position, because incorrect swap Id", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
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
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParamsFirst.openTimestamp);
        await openSwapPayFixed(testData, derivativeParamsFirst);

        await assertError(
            //when
            miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(0, openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS)),
            //then
            "IPOR_304"
        );
    });

    it("should NOT close position, because swap has incorrect status - pay fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
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
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC.add(USD_28_000_18DEC),
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);

        const endTimestamp = openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS);

        await miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        await assertError(
            //when
            miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_305"
        );
    });

    it("should NOT close position, because swap has incorrect status - receive fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
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
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC.add(USD_28_000_18DEC),
                derivativeParamsFirst.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            from: openerUser,
        };
        await openSwapReceiveFixed(testData, derivativeParams25days);

        const endTimestamp = openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS);

        await miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);

        await assertError(
            //when
            miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_305"
        );
    });

    it("should NOT close position, because swap not exists", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const closerUser = userTwo;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await assertError(
            //when
            miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(0, openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS)),
            //then
            "IPOR_304"
        );
    });

    it("should NOT close position, pay fixed, single id function, DAI, when contract is paused", async () => {
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
                BigNumber.from("1"),
                (contract) => {
                    return contract.closeSwapPayFixed(1);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, pay fixed, multiple ids function, DAI, when contract is paused", async () => {
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
                BigNumber.from("1"),
                (contract) => {
                    return contract.closeSwapsPayFixed([1]);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, receive fixed, single id function, DAI, when contract is paused", async () => {
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
                BigNumber.from("1"),
                (contract) => {
                    return contract.closeSwapReceiveFixed(1);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, receive fixed, multiple ids function, DAI, when contract is paused", async () => {
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
                BigNumber.from("1"),
                (contract) => {
                    return contract.closeSwapsReceiveFixed([1]);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, pay fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
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
                0,
                userTwo,
                userTwo,
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
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, pay fixed, single id emergency function, DAI, when contract is paused", async () => {
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
                0,
                userTwo,
                userTwo,
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
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, receive fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
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
                BigNumber.from("1"),
                (contract) => {
                    return contract.emergencyCloseSwapsReceiveFixed([1]);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, receive fixed, single id emergency function, DAI, when contract is paused", async () => {
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
                BigNumber.from("1"),
                (contract) => {
                    return contract.emergencyCloseSwapReceiveFixed(1);
                },
                ZERO,
                true,
                admin,
                userOne,
                liquidityProvider
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position by owner, pay fixed, multiple ids emergency function, DAI, when contract is not paused", async () => {
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
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, pay fixed, single id emergency function, DAI, when contract is not paused", async () => {
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
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, receive fixed, multiple ids emergency function, DAI, when contract is not paused", async () => {
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
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, receive fixed, single id emergency function, DAI, when contract is not paused", async () => {
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
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close two receive fixed position using multicall function when one of is is not valid, DAI", async () => {
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
                BigNumber.from("2"),
                (contract) => {
                    return contract.closeSwapsReceiveFixed([1, 300]);
                },
                ZERO,
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "IPOR_305"
        );
    });

    it("should NOT close two pay fixed position using multicall function when one of is is not valid, DAI", async () => {
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
                0,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                BigNumber.from("2"),
                (contract) => {
                    return contract.closeSwapsPayFixed([1, 300]);
                },
                ZERO,
                false,
                admin,
                userOne,
                liquidityProvider
            ),
            "IPOR_305"
        );
    });

    //  ##########################

    it("should close only one position - close first position", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
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
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
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
        await warren
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
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
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

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
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
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
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
        await warren
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
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
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
        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const expectedIncomeFeeValue = BigNumber.from("636796358352768143662");
        const expectedPositionValue = BigNumber.from("6367963583527681436620");
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
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
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

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueBeforeOpenSwap, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        const endTimestamp = params.openTimestamp.add(periodOfTimeElapsedInSeconds);
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueAfterOpenSwap, params.openTimestamp);

        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        await warren
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

    it("should open many positions and arrays with ids have correct state, one user", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
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
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        const expectedUserDerivativeIdsLength = 3;

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(3).mul(USD_28_000_18DEC),
                derivativeParams.openTimestamp
            );

        //when
        await openSwapPayFixed(testData, derivativeParams);
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await openSwapPayFixed(testData, derivativeParams);
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await openSwapPayFixed(testData, derivativeParams);

        //then
        const actualUserDerivativeResponse = await miltonStorageDai.getSwapPayFixedIds(
            await userTwo.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIds = actualUserDerivativeResponse.ids;

        expect(
            expectedUserDerivativeIdsLength,
            `Incorrect user swap ids length actual: ${actualUserDerivativeIds.length}, expected: ${expectedUserDerivativeIdsLength}`
        ).to.be.eq(actualUserDerivativeIds.length);

        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 1, 0, 0, 0);
        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 2, 0, 1, 1);
        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 3, 0, 2, 2);
    });

    it("should open many positions and arrays with ids have correct state, two users", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        const expectedUserDerivativeIdsLengthFirst = 2;
        const expectedUserDerivativeIdsLengthSecond = 1;

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(3).mul(USD_28_000_18DEC),
                derivativeParams.openTimestamp
            );

        //when
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //then
        const actualUserDerivativeResponseFirst = await miltonStorageDai.getSwapPayFixedIds(
            await userTwo.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond = await miltonStorageDai.getSwapPayFixedIds(
            await userThree.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsSecond = actualUserDerivativeResponseSecond.ids;

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);

        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 1, 0, 0, 0);
        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 2, 0, 1, 0);
        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 3, 0, 2, 1);
    });

    it("should open many positions and close one position and arrays with ids have correct state, two users", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        const expectedUserDerivativeIdsLengthFirst = 2;
        const expectedUserDerivativeIdsLengthSecond = 0;

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(3).mul(USD_28_000_18DEC),
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS));

        //then
        const actualUserDerivativeResponseFirst = await miltonStorageDai.getSwapPayFixedIds(
            await userTwo.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond = await miltonStorageDai.getSwapPayFixedIds(
            await userThree.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsSecond = actualUserDerivativeResponseSecond.ids;

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);

        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 1, 0, 0, 0);
        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 3, 0, 1, 1);
    });

    it("should open many positions and close two positions and arrays with ids have correct state, two users", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        const expectedUserDerivativeIdsLengthFirst = 1;
        const expectedUserDerivativeIdsLengthSecond = 0;

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(3).mul(USD_28_000_18DEC),
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS));
        await miltonDai
            .connect(userTwo)
            .itfCloseSwapPayFixed(3, derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS));

        //then
        const actualUserDerivativeResponseFirst = await miltonStorageDai.getSwapPayFixedIds(
            await userTwo.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond = await miltonStorageDai.getSwapPayFixedIds(
            await userThree.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsSecond = actualUserDerivativeResponseSecond.ids;

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);

        await assertMiltonDerivativeItem(testData, derivativeParams.asset, 1, 0, 0, 0);
    });

    it("should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(2).mul(USD_28_000_18DEC),
                derivativeParams.openTimestamp
            );
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        const expectedUserDerivativeIdsLengthFirst = 0;
        const expectedUserDerivativeIdsLengthSecond = 0;

        //position 1, user first
        await openSwapPayFixed(testData, derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(1, derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS));
        await miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS));

        //then
        const actualUserDerivativeResponseFirst = await miltonStorageDai.getSwapPayFixedIds(
            await userTwo.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond = await miltonStorageDai.getSwapPayFixedIds(
            await userThree.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsSecond = actualUserDerivativeResponseSecond.ids;

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
    });

    it("should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1 with minus 3", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(2).mul(USD_28_000_18DEC),
                derivativeParams.openTimestamp
            );
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        const expectedUserDerivativeIdsLengthFirst = 0;
        const expectedUserDerivativeIdsLengthSecond = 0;

        //position 1, user first
        await openSwapPayFixed(testData, derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp
            .add(PERIOD_25_DAYS_IN_SECONDS)
            .sub(BigNumber.from("3"));
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(1, derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS));
        await miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS));

        //then
        const actualUserDerivativeResponseFirst = await miltonStorageDai.getSwapPayFixedIds(
            await userTwo.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond = await miltonStorageDai.getSwapPayFixedIds(
            await userThree.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsSecond = actualUserDerivativeResponseSecond.ids;

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
    });

    it("should open two positions and close one position - Arithmetic overflow - last byte difference - case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        const derivativeParams = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigNumber.from(2).mul(USD_28_000_18DEC),
                derivativeParams.openTimestamp
            );
        await warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        const expectedUserDerivativeIdsLengthFirst = 0;
        const expectedUserDerivativeIdsLengthSecond = 0;

        //position 1, user first
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        await miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(1, derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS));

        //when
        await miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS));

        //then
        const actualUserDerivativeResponseFirst = await miltonStorageDai.getSwapPayFixedIds(
            await userTwo.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond = await miltonStorageDai.getSwapPayFixedIds(
            await userThree.getAddress(),
            0,
            10
        );
        const actualUserDerivativeIdsSecond = actualUserDerivativeResponseSecond.ids;

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
    });

    // // ####################################

    it("should calculate income fee, 5%, not owner, Milton loses, user earns, |I| < D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

        const expectedIncomeFeeValue = BigNumber.from("420798965789715138682");
        const expectedIncomeFeeValueWad = BigNumber.from("420798965789715138682");
        const expectedPositionValue = BigNumber.from("8415979315794302773646");
        const expectedPositionValueWad = BigNumber.from("8415979315794302773646");

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

    it("should calculate income fee, 5%, Milton loses, user earns, |I| > D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

    it("should calculate income fee, 5%, Milton earns, user loses, |I| < D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

        const expectedIncomeFeeValue = BigNumber.from("395949708238213469173");
        const expectedIncomeFeeValueWad = BigNumber.from("395949708238213469173");
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

    it("should calculate income fee, 5%, Milton earns, user loses, |I| > D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
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

        const expectedIncomeFeeValue = BigNumber.from("498350494851544536639");
        const expectedIncomeFeeValueWad = BigNumber.from("498350494851544536639");
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

    it("should calculate income fee, 100%, Milton loses, user earns, |I| < D", async () => {
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

        const expectedIncomeFeeValue = BigNumber.from("8415979315794302773646");
        const expectedIncomeFeeValueWad = BigNumber.from("8415979315794302773646");
        const expectedPositionValue = BigNumber.from("8415979315794302773646");
        const expectedPositionValueWad = BigNumber.from("8415979315794302773646");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_119_18DEC,
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

    it("should calculate income fee, 100%, Milton loses, user earns, |I| > D", async () => {
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

        const expectedIncomeFeeValue = TC_COLLATERAL_18DEC;
        const expectedIncomeFeeValueWad = TC_COLLATERAL_18DEC;
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

    it("should calculate income fee, 100%, Milton earns, user loses, |I| < D, to low liquidity pool", async () => {
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

        const expectedIncomeFeeValue = BigNumber.from("7918994164764269383465");
        const expectedIncomeFeeValueWad = BigNumber.from("7918994164764269383465");
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

    it("should calculate income fee, 100%, Milton earns, user loses, |I| > D, to low liquidity pool", async () => {
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

        const expectedIncomeFeeValue = TC_COLLATERAL_18DEC;
        const expectedIncomeFeeValueWad = TC_COLLATERAL_18DEC;
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
            PERCENTAGE_160_18DEC,
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

    // #####################

    it("should NOT open pay fixed position, DAI, leverage too low", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: BigNumber.from(500),
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                ),
            //then
            "IPOR_306"
        );
    });

    it("should NOT open pay fixed position, DAI, leverage too high", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, warren, miltonDai } = testData;
        if (tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: BigNumber.from("1000000000000000000001"),
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await assertError(
            //when
            miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                ),
            //then
            "IPOR_307"
        );
    });

    it("should calculate Pay Fixed Position Value - simple case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { tokenDai, josephDai, warren, miltonDai, miltonStorageDai } = testData;
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

        await warren
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
});
