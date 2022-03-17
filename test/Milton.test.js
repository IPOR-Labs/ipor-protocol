const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_4_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_119_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_121_18DEC,
    PERCENTAGE_149_18DEC,
    PERCENTAGE_150_18DEC,
    PERCENTAGE_151_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_161_18DEC,

    PERCENTAGE_365_18DEC,
    PERCENTAGE_366_18DEC,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
    USD_10_18DEC,
    USD_20_18DEC,
    USD_10_000_6DEC,
    USD_28_000_18DEC,
    USD_28_000_6DEC,
    USD_10_000_000_6DEC,
    USD_10_000_000_18DEC,
    LEVERAGE_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    TC_COLLATERAL_18DEC,
    TC_OPENING_FEE_6DEC,
    TC_OPENING_FEE_18DEC,
    TC_INCOME_TAX_18DEC,
    SPECIFIC_INCOME_TAX_CASE_1,
    SPECIFIC_INTEREST_AMOUNT_CASE_1,
    TC_COLLATERAL_6DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_6DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_6DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    ZERO,
} = require("./Const.js");

const {
    assertError,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareComplexTestDataDaiCase00,
    prepareTestDataDaiCase000,
    prepareComplexTestDataDaiCase000,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");
const { PERIOD_27_DAYS_17_HOURS_IN_SECONDS } = require("./Const");

describe("Milton", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });

    it("should NOT open position because totalAmount amount too low", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const totalAmount = 0;
        const toleratedQuoteValue = 3;
        const leverage = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);
        await assertError(
            //when
            testData.miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                toleratedQuoteValue,
                leverage
            ),
            //then
            "IPOR_308"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - pay fixed 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const totalAmount = BigInt("30000000000000000001");
        const toleratedQuoteValue = BigInt("39999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(testData.tokenDai.address, PERCENTAGE_3_18DEC, timestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, timestamp);

        await assertError(
            //when
            testData.miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                toleratedQuoteValue,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - receive fixed 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const totalAmount = BigInt("30000000000000000001");
        const toleratedQuoteValue = BigInt("19999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(testData.tokenDai.address, PERCENTAGE_3_18DEC, timestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, timestamp);

        await assertError(
            //when
            testData.miltonDai.itfOpenSwapReceiveFixed(
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
            data,
            0,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const totalAmount = BigInt("30000001");
        const toleratedQuoteValue = BigInt("39999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(testData.tokenUsdt.address, PERCENTAGE_3_18DEC, timestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, timestamp);

        await assertError(
            //when
            testData.miltonUsdt.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                toleratedQuoteValue,
                leverage
            ),
            //then
            "IPOR_312"
        );
    });

    it("should NOT open position because tolerated quote value exceeded - receive fixed 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const totalAmount = BigInt("30000001");
        const toleratedQuoteValue = BigInt("19999999999999999");
        const leverage = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(testData.tokenUsdt.address, PERCENTAGE_3_18DEC, timestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, timestamp);

        await assertError(
            //when
            testData.miltonUsdt.itfOpenSwapReceiveFixed(
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
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const totalAmount = BigInt("1000000000000000000000001");
        const toleratedQuoteValue = 3;
        const leverage = BigInt(10000000000000000000);
        const timestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            testData.miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                toleratedQuoteValue,
                leverage
            ),
            //then
            "IPOR_310"
        );
    });

    it("should NOT open position because totalAmount amount too high - case 2", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const totalAmount = BigInt("100688870576704582165765");
        const toleratedQuoteValue = 3;
        const leverage = BigInt(10000000000000000000);
        const timestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            testData.miltonDai.itfOpenSwapPayFixed(
                timestamp,
                totalAmount,
                toleratedQuoteValue,
                leverage
            ),
            //then
            "IPOR_310"
        );
    });

    it("should open pay fixed position - simple case DAI - 18 decimals", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        let collateralWad = TC_COLLATERAL_18DEC;
        let openingFee = TC_OPENING_FEE_18DEC;

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad + params.totalAmount;
        let expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad + openingFee;
        let expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await testData.miltonDai
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
            BigInt("9990000000000000000000000"),
            BigInt("9990000000000000000000000"),
            expectedLiquidityPoolTotalBalanceWad,
            1,
            TC_COLLATERAL_18DEC,
            USD_20_18DEC,
            BigInt("0")
        );

        const actualPayFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonDai.getAccruedBalance()
            ).payFixedSwaps
        );
        const actualRecFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonDai.getAccruedBalance()
            ).receiveFixedSwaps
        );
        const actualDerivativesTotalBalanceWad =
            actualPayFixDerivativesBalanceWad + actualRecFixDerivativesBalanceWad;

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
            data,
            0,
            1,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, testData);

        let collateralWad = TC_COLLATERAL_18DEC;
        let openingFee = TC_OPENING_FEE_18DEC;

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        let miltonBalanceBeforePayout = USD_28_000_6DEC;
        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayout, params.openTimestamp);

        let expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayout + params.totalAmount;
        let expectedLiquidityPoolTotalBalanceWad = miltonBalanceBeforePayoutWad + openingFee;
        let expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await testData.miltonUsdt
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
            BigInt("9990000000000"),
            BigInt("9990000000000"),
            expectedLiquidityPoolTotalBalanceWad,
            1,
            TC_COLLATERAL_18DEC,
            USD_20_18DEC,
            BigInt("0")
        );
        const actualPayFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonUsdt.getAccruedBalance()
            ).payFixedSwaps
        );

        const actualRecFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonUsdt.getAccruedBalance()
            ).receiveFixedSwaps
        );

        const actualDerivativesTotalBalanceWad =
            actualPayFixDerivativesBalanceWad + actualRecFixDerivativesBalanceWad;

        expect(
            expectedDerivativesTotalBalanceWad,
            `Incorrect derivatives total balance for ${params.asset} actual ${actualDerivativesTotalBalanceWad}, expected ${expectedDerivativesTotalBalanceWad}Wad`
        ).to.be.eq(actualDerivativesTotalBalanceWad);
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        let liquidationDepositAmount = USD_20_18DEC;

        let expectedIncomeFeeValue = BigInt("0");
        let expectedIncomeFeeValueWad = BigInt("0");

        let totalAmount = TC_TOTAL_AMOUNT_10_000_18DEC;
        let collateral = TC_COLLATERAL_18DEC;
        let openingFee = TC_OPENING_FEE_18DEC;

        let diffAfterClose = totalAmount - collateral - liquidationDepositAmount;

        let expectedOpenerUserUnderlyingTokenBalanceAfterPayOut =
            USER_SUPPLY_10MLN_18DEC - diffAfterClose;
        let expectedCloserUserUnderlyingTokenBalanceAfterPayOut =
            USER_SUPPLY_10MLN_18DEC - diffAfterClose;

        let expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayoutWad + diffAfterClose;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee - expectedIncomeFeeValue;

        let expectedPositionValue = BigInt("0");

        await exetuceCloseSwapTestCase(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_4_18DEC,
            0,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
            expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalanceWad,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValue,
            ZERO,
            null,
            expectedPositionValue,
            expectedIncomeFeeValue
        );
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValueWad = BigInt("6826719107555404611");
        let expectedPositionValue = BigInt("-68267191075554046114");
        let expectedPositionValueWad = BigInt("-68267191075554046114");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_366_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, USDT, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, USDT 6 decimals", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            1,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValueWad = BigInt("6826719107555404611");
        let expectedPositionValue = BigInt("-68267191");
        let expectedPositionValueWad = BigInt("-68267191075554046114");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_366_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should NOT open position because Liquidity Pool balance is to low", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: BigInt("10000000000000000000000"), //10 000 USD
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        let closeSwapTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, BigInt("10000000000000000"), params.openTimestamp);

        await openSwapPayFixed(testData, params);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, BigInt("1600000000000000000"), params.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, BigInt("50000000000000000"), closeSwapTimestamp);

        await testData.miltonStorageDai.setJoseph(userOne.address);

        await testData.miltonStorageDai
            .connect(userOne)
            .subtractLiquidity(BigInt("20000000000000000000000"));

        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);

        //when
        await assertError(
            //when
            testData.miltonDai.connect(userTwo).itfCloseSwapPayFixed(1, closeSwapTimestamp),
            //then
            "IPOR_319"
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > totalAmount, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost > totalAmount, before maturity, USDT 6 decimals", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            1,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_6DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValueWad = BigInt("791899416476426938347");
        let expectedPositionValue = BigInt("-7918994164764269383465");
        let expectedPositionValueWad = BigInt("-7918994164764269383465");
        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, USDT 6 decimals", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            1,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValueWad = BigInt("791899416476426938347");
        let expectedPositionValue = BigInt("-7918994165");
        let expectedPositionValueWad = BigInt("-7918994164764269383465");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValueWad = BigInt("856889782380354383694");
        let expectedPositionValue = BigInt("-8568897823803543836942");
        let expectedPositionValueWad = BigInt("-8568897823803543836942");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, USDT 6 decimals", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            1,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = BigInt("996700990");
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_6DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, DAI 18 decimals", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("778245978261316123526");
        let expectedIncomeFeeValueWad = BigInt("778245978261316123526");

        let expectedPositionValue = BigInt("7782459782613161235257");
        let expectedPositionValueWad = BigInt("7782459782613161235257");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, USDT 6 decimals", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            1,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = BigInt("778245978");
        let expectedIncomeFeeValueWad = BigInt("778245978261316123526");
        let expectedPositionValue = BigInt("7782459782");
        let expectedPositionValueWad = BigInt("7782459782613161235257");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenUsdt.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = SPECIFIC_INCOME_TAX_CASE_1;
        let expectedIncomeFeeValueWad = SPECIFIC_INCOME_TAX_CASE_1;
        let expectedPositionValue = SPECIFIC_INTEREST_AMOUNT_CASE_1;
        let expectedPositionValueWad = SPECIFIC_INTEREST_AMOUNT_CASE_1;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, 100% Deposit > User earned > 99% Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeTaxValue = BigInt("989874270595533665253");
        let expectedIncomeTaxValueWad = BigInt("989874270595533665253");
        let expectedPositionValue = BigInt("9898742705955336652531");
        let expectedPositionValueWad = BigInt("9898742705955336652531");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_151_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            null,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, 7 hours before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        let endTimestamp = params.openTimestamp + PERIOD_27_DAYS_17_HOURS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Deposit, 5 hours before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeTaxValue = BigInt("865150112500496428963");
        let expectedIncomeTaxValueWad = BigInt("865150112500496428963");
        let expectedPositionValue = BigInt("8651501125004964289632");
        let expectedPositionValueWad = BigInt("8651501125004964289632");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            null,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("636796358352768143662");
        let expectedIncomeFeeValueWad = BigInt("636796358352768143662");
        let expectedPositionValue = BigInt("6367963583527681436620");
        let expectedPositionValueWad = BigInt("6367963583527681436620");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, 100% Deposit > User lost > 99% Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeTaxValue = BigInt("989874270595533672762");
        let expectedIncomeTaxValueWad = BigInt("989874270595533672762");
        let expectedPositionValue = BigInt("-9898742705955336727624");
        let expectedPositionValueWad = BigInt("-9898742705955336727624");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_150_18DEC,
            PERCENTAGE_6_18DEC,
            PERCENTAGE_151_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            null,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: PERCENTAGE_121_18DEC,
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai.connect(userThree).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("856889782380354383694");
        let expectedIncomeFeeValueWad = BigInt("856889782380354383694");
        let expectedPositionValue = BigInt("-8568897823803543836942");
        let expectedPositionValueWad = BigInt("-8568897823803543836942");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, 5 hours before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeTaxValue = BigInt("880328184649627945216");
        let expectedIncomeTaxValueWad = BigInt("880328184649627945216");
        let expectedPositionValue = BigInt("-8803281846496279452160");
        let expectedPositionValueWad = BigInt("-8803281846496279452160");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_27_DAYS_19_HOURS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            null,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price not changed, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("6826719107555402563");
        let expectedIncomeFeeValueWad = BigInt("6826719107555402563");
        let expectedPositionValue = BigInt("-68267191075554025634");
        let expectedPositionValueWad = BigInt("-68267191075554025634");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_3_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price changed 25%, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValueWad = BigInt("6826719107555404611");
        let expectedPositionValue = BigInt("-68267191075554046114");
        let expectedPositionValueWad = BigInt("-68267191075554046114");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("279895483409771589481");
        let expectedIncomeFeeValueWad = BigInt("279895483409771589481");
        let expectedPositionValue = BigInt("-2798954834097715894807");
        let expectedPositionValueWad = BigInt("-2798954834097715894807");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("791899416476426932749");
        let expectedIncomeFeeValueWad = BigInt("791899416476426932749");
        let expectedPositionValue = BigInt("-7918994164764269327486");
        let expectedPositionValueWad = BigInt("-7918994164764269327486");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("841597931579430277365");
        let expectedIncomeFeeValueWad = BigInt("841597931579430277365");
        let expectedPositionValue = BigInt("8415979315794302773646");
        let expectedPositionValueWad = BigInt("8415979315794302773646");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("652088209153692249992");
        let expectedIncomeFeeValueWad = BigInt("652088209153692249992");
        let expectedPositionValue = BigInt("-6520882091536922499916");
        let expectedPositionValueWad = BigInt("-6520882091536922499916");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, 100% Deposit > User earned > 99% Deposit, before maturity", async () => {
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeTaxValue = BigInt("989874270595533672080");
        let expectedIncomeTaxValueWad = BigInt("989874270595533672080");
        let expectedPositionValue = BigInt("9898742705955336720799");
        let expectedPositionValueWad = BigInt("9898742705955336720799");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_151_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_151_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            null,
            expectedIncomeTaxValue,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("11900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, 7 hours before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("11900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        let endTimestamp = params.openTimestamp + PERIOD_27_DAYS_17_HOURS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, 100% Deposit > User lost > 99% Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeTaxValue = BigInt("989874270595533666618");
        let expectedIncomeTaxValueWad = BigInt("989874270595533666618");
        let expectedPositionValue = BigInt("-9898742705955336666184");
        let expectedPositionValueWad = BigInt("-9898742705955336666184");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_149_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            null,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);
        await openSwapReceiveFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_120_18DEC, params.openTimestamp);
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai.connect(userThree).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_320"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("841597931579430277365");
        let expectedIncomeFeeValueWad = BigInt("841597931579430277365");
        let expectedPositionValue = BigInt("8415979315794302773646");
        let expectedPositionValueWad = BigInt("8415979315794302773646");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("652088209153692249992");
        let expectedIncomeFeeValueWad = BigInt("652088209153692249992");
        let expectedPositionValue = BigInt("-6520882091536922499916");
        let expectedPositionValueWad = BigInt("-6520882091536922499916");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeFeeValueWad = TC_INCOME_TAX_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_161_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should NOT close position, because incorrect swap Id", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParamsFirst.openTimestamp);
        await openSwapPayFixed(testData, derivativeParamsFirst);

        await assertError(
            //when
            testData.miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(0, openTimestamp + PERIOD_25_DAYS_IN_SECONDS),
            //then
            "IPOR_304"
        );
    });

    it("should NOT close position, because swap has incorrect status - pay fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC + USD_28_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);

        const endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        await assertError(
            //when
            testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_305"
        );
    });

    it("should NOT close position, because swap has incorrect status - receive fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC + USD_28_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openSwapReceiveFixed(testData, derivativeParams25days);

        const endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await testData.miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);

        await assertError(
            //when
            testData.miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_305"
        );
    });

    it("should NOT close position, because swap not exists", async () => {
        //given
        const testData = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        let closerUser = userTwo;
        let openTimestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            testData.miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(0, openTimestamp + PERIOD_25_DAYS_IN_SECONDS),
            //then
            "IPOR_304"
        );
    });

    it("should close only one position - close first position", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC + USD_28_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);
        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(2);

        //when
        await testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        //then
        const actualDerivatives = await testData.miltonStorageDai.getSwapsPayFixed(
            derivativeParams25days.from.address,
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
        ).to.be.eq(BigInt(oneDerivative.id));
    });

    it("should close only one position - close last position", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC + USD_28_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);
        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(1);

        //when
        await testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(2, endTimestamp);

        //then
        const actualDerivatives = await testData.miltonStorageDai.getSwapsPayFixed(
            derivativeParams25days.from.address,
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
        ).to.be.eq(BigInt(oneDerivative.id));
    });

    it("should close position with appropriate balance, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity, IPOR index calculated before close", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        let expectedIncomeFeeValue = BigInt("636796358352768143662");
        let expectedPositionValue = BigInt("6367963583527681436620");
        let leverage = USD_10_18DEC;
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_5_18DEC;
        let iporValueAfterOpenSwap = PERCENTAGE_50_18DEC;
        let periodOfTimeElapsedInSeconds = PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositions = 0;
        let expectedDerivativesTotalBalanceWad = ZERO;
        let expectedLiquidationDepositTotalBalanceWad = ZERO;
        let expectedTreasuryTotalBalanceWad = expectedIncomeFeeValue;
        let expectedSoap = ZERO;
        let openTimestamp = null;

        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;

        let closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        let openerUserLost =
            TC_OPENING_FEE_18DEC +
            TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
            expectedPositionValue +
            expectedIncomeFeeValue;

        let closerUserLost = null;
        let openerUserEarned = null;

        if (openerUser.address === closerUser.address) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad +
            TC_OPENING_FEE_18DEC +
            TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            expectedPositionValue +
            expectedIncomeFeeValue;

        let expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC + openerUserEarned - openerUserLost;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC + closerUserEarned - closerUserLost;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad - expectedPositionValue + TC_OPENING_FEE_18DEC;

        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }
        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: leverage,
            openTimestamp: localOpenTimestamp,
            from: openerUser,
        };

        if (miltonBalanceBeforePayoutWad != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await testData.josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueBeforeOpenSwap, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueAfterOpenSwap, params.openTimestamp);

        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueAfterOpenSwap, endTimestamp - 1);

        //additional check for position value and for incomeFee value
        const actualPositionValue = await testData.miltonDai
            .connect(params.from)
            .itfCalculateSwapPayFixedValue(endTimestamp, 1);

        const actualIncomeFeeValue = await testData.miltonDai
            .connect(params.from)
            .itfCalculateIncomeFeeValue(actualPositionValue);

        expect(actualPositionValue, "Incorrect position value").to.be.eq(expectedPositionValue);
        expect(actualIncomeFeeValue, "Incorrect income fee value").to.be.eq(expectedIncomeFeeValue);

        //when
        await testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

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
            expectedLiquidationDepositTotalBalanceWad,
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
            data
        );

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLength = 3;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(3) * USD_28_000_18DEC, derivativeParams.openTimestamp);

        //when
        await openSwapPayFixed(testData, derivativeParams);
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openSwapPayFixed(testData, derivativeParams);
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openSwapPayFixed(testData, derivativeParams);

        //then
        const actualUserDerivativeResponse = await testData.miltonStorageDai.getSwapPayFixedIds(
            userTwo.address,
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
            data
        );

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 1;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(3) * USD_28_000_18DEC, derivativeParams.openTimestamp);

        //when
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //then
        const actualUserDerivativeResponseFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address, 0, 10);
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userThree.address, 0, 10);
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
            data
        );

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 0;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(3) * USD_28_000_18DEC, derivativeParams.openTimestamp);

        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS);

        //then
        const actualUserDerivativeResponseFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address, 0, 10);
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userThree.address, 0, 10);
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
            data
        );

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 1;
        let expectedUserDerivativeIdsLengthSecond = 0;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(3) * USD_28_000_18DEC, derivativeParams.openTimestamp);

        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS);
        await testData.miltonDai
            .connect(userTwo)
            .itfCloseSwapPayFixed(3, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS);

        //then
        const actualUserDerivativeResponseFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address, 0, 10);
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userThree.address, 0, 10);
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
            data
        );

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;

        //position 1, user first
        await openSwapPayFixed(testData, derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(1, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS);
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS);

        //then
        const actualUserDerivativeResponseFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address, 0, 10);
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userThree.address, 0, 10);
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
            data
        );

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;

        //position 1, user first
        await openSwapPayFixed(testData, derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS - 3;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(1, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS);
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS);

        //then
        const actualUserDerivativeResponseFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address, 0, 10);
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userThree.address, 0, 10);
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
            data
        );

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;

        //position 1, user first
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(1, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS);

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(2, derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS);

        //then
        const actualUserDerivativeResponseFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address, 0, 10);
        const actualUserDerivativeIdsFirst = actualUserDerivativeResponseFirst.ids;
        const actualUserDerivativeResponseSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userThree.address, 0, 10);
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

    it("should calculate income fee, 5%, not owner, Milton loses, user earns, |I| < D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            2,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = BigInt("420798965789715138682");
        let expectedIncomeFeeValueWad = BigInt("420798965789715138682");
        let expectedPositionValue = BigInt("8415979315794302773646");
        let expectedPositionValueWad = BigInt("8415979315794302773646");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate income fee, 5%, Milton loses, user earns, |I| > D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            2,
            1,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = BigInt("498350494851544536639");
        let expectedIncomeFeeValueWad = BigInt("498350494851544536639");

        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate income fee, 5%, Milton earns, user loses, |I| < D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            2,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = BigInt("395949708238213469173");
        let expectedIncomeFeeValueWad = BigInt("395949708238213469173");
        let expectedPositionValue = BigInt("-7918994164764269383465");
        let expectedPositionValueWad = BigInt("-7918994164764269383465");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate income fee, 5%, Milton earns, user loses, |I| > D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            2,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = BigInt("498350494851544536639");
        let expectedIncomeFeeValueWad = BigInt("498350494851544536639");
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate income fee, 100%, Milton loses, user earns, |I| < D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = BigInt("8415979315794302773646");
        let expectedIncomeFeeValueWad = BigInt("8415979315794302773646");
        let expectedPositionValue = BigInt("8415979315794302773646");
        let expectedPositionValueWad = BigInt("8415979315794302773646");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_119_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate income fee, 100%, Milton loses, user earns, |I| > D", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = TC_COLLATERAL_18DEC;
        let expectedIncomeFeeValueWad = TC_COLLATERAL_18DEC;
        let expectedPositionValue = TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_6_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValue,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate income fee, 100%, Milton earns, user loses, |I| < D, to low liquidity pool", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = BigInt("7918994164764269383465");
        let expectedIncomeFeeValueWad = BigInt("7918994164764269383465");
        let expectedPositionValue = BigInt("-7918994164764269383465");
        let expectedPositionValueWad = BigInt("-7918994164764269383465");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_121_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate income fee, 100%, Milton earns, user loses, |I| > D, to low liquidity pool", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let expectedIncomeFeeValue = TC_COLLATERAL_18DEC;
        let expectedIncomeFeeValueWad = TC_COLLATERAL_18DEC;
        let expectedPositionValue = -TC_COLLATERAL_18DEC;
        let expectedPositionValueWad = -TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userThree,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_50_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            null,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should open pay fixed position, DAI, custom Opening Fee for Treasury 50%", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            4,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        let expectedOpeningFeeTotalBalanceWad = TC_OPENING_FEE_18DEC;
        let expectedTreasuryTotalBalanceWad = BigInt("149505148455463361");

        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        let expectedLiquidityPoolTotalBalanceWad = BigInt("28002840597820653803859");

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        //then
        let balance = await testData.miltonStorageDai.getExtendedBalance();

        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidityPoolTotalBalanceWad = BigInt(balance.liquidityPool);
        const actualTreasuryTotalBalanceWad = BigInt(balance.treasury);

        expect(
            expectedOpeningFeeTotalBalanceWad,
            `Incorrect opening fee total balance for ${params.asset}, actual:  ${actualOpeningFeeTotalBalance},
            expected: ${expectedOpeningFeeTotalBalanceWad}`
        ).to.be.eq(actualOpeningFeeTotalBalance);
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
            data,
            5,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        let expectedOpeningFeeTotalBalanceWad = TC_OPENING_FEE_18DEC;
        let expectedTreasuryTotalBalanceWad = BigInt("74752574227731681");

        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        let expectedLiquidityPoolTotalBalanceWad = BigInt("28002915350394881535539");
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        //then
        let balance = await testData.miltonStorageDai.getExtendedBalance();

        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidityPoolTotalBalanceWad = BigInt(balance.liquidityPool);
        const actualTreasuryTotalBalanceWad = BigInt(balance.treasury);

        expect(
            expectedOpeningFeeTotalBalanceWad,
            `Incorrect opening fee total balance for ${params.asset}, actual:  ${actualOpeningFeeTotalBalance},
            expected: ${expectedOpeningFeeTotalBalanceWad}`
        ).to.be.eq(actualOpeningFeeTotalBalance);
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

    it("should NOT open pay fixed position, DAI, leverage too low", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: BigInt(500),
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai
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
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: BigInt("1000000000000000000001"),
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai
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

    it("should open pay fixed position, DAI, custom leverage - simple case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: BigInt("15125000000000000000"),
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.toleratedQuoteValue,
                params.leverage
            );

        //then
        let actualDerivativeItem = await testData.miltonStorageDai.getSwapPayFixed(1);
        let actualNotionalAmount = BigInt(actualDerivativeItem.notionalAmount);
        let expectedNotionalAmount = BigInt("150751024692592222333298");

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
            data
        );

        let veryLongTimeAgoTimestamp = 31536000; //1971-01-01
        let expectedIncomeFeeValue = ZERO;
        let expectedIncomeFeeValueWad = ZERO;
        let expectedPositionValue = ZERO;
        let expectedPositionValueWad = ZERO;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_3_18DEC,
            PERCENTAGE_4_18DEC,
            0,
            0,
            ZERO,
            ZERO,
            expectedIncomeFeeValueWad,
            ZERO,
            veryLongTimeAgoTimestamp,
            expectedIncomeFeeValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate Pay Fixed Position Value - simple case 1", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const params = getPayFixedDerivativeParamsDAICase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);
        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(miltonBalanceBeforePayoutWad, params.openTimestamp);
        await openSwapPayFixed(testData, params);
        let derivativeItem = await testData.miltonStorageDai.getSwapPayFixed(1);

        let expectedPositionValue = BigInt("-38229627002310297226");

        //when
        let actualPositionValue = BigInt(
            await testData.miltonDai.itfCalculateSwapPayFixedValue(
                params.openTimestamp + PERIOD_14_DAYS_IN_SECONDS,
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
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                0,
                (contract) => {
                    return contract.closeSwapsPayFixed([]);
                },
                0,
                false
            ),
            "IPOR_315"
        );
    });

    it("should close single pay fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testCaseWhenUserClosesPositions(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            1,
            (contract) => {
                return contract.closeSwapsPayFixed([1]);
            },
            0,
            false
        );
    });

    it("should close two pay fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testCaseWhenUserClosesPositions(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            2,
            (contract) => {
                return contract.closeSwapsPayFixed([1, 2]);
            },
            0,
            false
        );
    });

    it("should NOT close two pay fixed position using multicall function when one of is is not valid, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                2,
                (contract) => {
                    return contract.closeSwapsPayFixed([1, 300]);
                },
                0,
                false
            ),
            "IPOR_305"
        );
    });

    it("should fail to close receive fixed positions using multicall function when list of swaps is empty, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                0,
                (contract) => {
                    return contract.closeSwapsReceiveFixed([]);
                },
                0,
                false
            ),
            "IPOR_315"
        );
    });

    it("should close single receive fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testCaseWhenUserClosesPositions(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            1,
            (contract) => {
                return contract.closeSwapsReceiveFixed([1]);
            },
            0,
            false
        );
    });

    it("should close two receive fixed position using multicall function, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testCaseWhenUserClosesPositions(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            2,
            (contract) => {
                return contract.closeSwapsReceiveFixed([1, 2]);
            },
            0,
            false
        );
    });

    it("should NOT close two receive fixed position using multicall function when one of is is not valid, DAI", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                2,
                (contract) => {
                    return contract.closeSwapsReceiveFixed([1, 300]);
                },
                0,
                false
            ),
            "IPOR_305"
        );
    });

    it("should NOT close position, pay fixed, single id function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.closeSwapPayFixed(1);
                },
                0,
                true
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, pay fixed, multiple ids function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.closeSwapsPayFixed([1]);
                },
                0,
                true
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, receive fixed, single id function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.closeSwapReceiveFixed(1);
                },
                0,
                true
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, receive fixed, multiple ids function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.closeSwapsReceiveFixed([1]);
                },
                0,
                true
            ),
            "Pausable: paused"
        );
    });

    it("should NOT close position, pay fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.emergencyCloseSwapsPayFixed([1]);
                },
                0,
                true
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, pay fixed, single id emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.emergencyCloseSwapPayFixed(1);
                },
                0,
                true
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, receive fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.emergencyCloseSwapsReceiveFixed([1]);
                },
                0,
                true
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position, receive fixed, single id emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                userTwo,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.emergencyCloseSwapReceiveFixed(1);
                },
                0,
                true
            ),
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT close position by owner, pay fixed, multiple ids emergency function, DAI, when contract is not paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                admin,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.emergencyCloseSwapsPayFixed([1]);
                },
                0,
                false
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, pay fixed, single id emergency function, DAI, when contract is not paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                0,
                userTwo,
                admin,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.emergencyCloseSwapPayFixed(1);
                },
                0,
                false
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, receive fixed, multiple ids emergency function, DAI, when contract is not paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                admin,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.emergencyCloseSwapsReceiveFixed([1]);
                },
                0,
                false
            ),
            "Pausable: not paused"
        );
    });

    it("should NOT close position by owner, receive fixed, single id emergency function, DAI, when contract is not paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await assertError(
            testCaseWhenUserClosesPositions(
                testData,
                testData.tokenDai.address,
                USD_10_18DEC,
                1,
                userTwo,
                admin,
                PERCENTAGE_5_18DEC,
                PERCENTAGE_160_18DEC,
                PERIOD_25_DAYS_IN_SECONDS,
                USD_10_000_000_18DEC,
                1,
                (contract) => {
                    return contract.emergencyCloseSwapReceiveFixed(1);
                },
                0,
                false
            ),
            "Pausable: not paused"
        );
    });

    it("should close position by owner, pay fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testCaseWhenUserClosesPositions(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            1,
            (contract) => {
                return contract.emergencyCloseSwapsPayFixed([1]);
            },
            0,
            true
        );
    });

    it("should close position by owner, pay fixed, single id emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testCaseWhenUserClosesPositions(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            0,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            1,
            (contract) => {
                return contract.emergencyCloseSwapPayFixed(1);
            },
            0,
            true
        );
    });

    it("should close position by owner, receive fixed, multiple ids emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testCaseWhenUserClosesPositions(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            1,
            (contract) => {
                return contract.emergencyCloseSwapsReceiveFixed([1]);
            },
            0,
            true
        );
    });

    it("should close position by owner, receive fixed, single id emergency function, DAI, when contract is paused", async () => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3,
            1,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testCaseWhenUserClosesPositions(
            testData,
            testData.tokenDai.address,
            USD_10_18DEC,
            1,
            userTwo,
            admin,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            USD_10_000_000_18DEC,
            1,
            (contract) => {
                return contract.emergencyCloseSwapReceiveFixed(1);
            },
            0,
            true
        );
    });

    const calculateSoap = async (testData, params) => {
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            return await testData.miltonUsdt
                .connect(params.from)
                .itfCalculateSoap(params.calculateTimestamp);
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            return await testData.miltonUsdc
                .connect(params.from)
                .itfCalculateSoap(params.calculateTimestamp);
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            return await testData.miltonDai
                .connect(params.from)
                .itfCalculateSoap(params.calculateTimestamp);
        }
    };

    const openSwapPayFixed = async (testData, params) => {
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                );
        }
        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                );
        }
        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                );
        }
    };
    const openSwapReceiveFixed = async (testData, params) => {
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                );
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                );
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                );
        }
    };

    const countOpenSwaps = (derivatives) => {
        let count = 0;
        for (let i = 0; i < derivatives.swaps.length; i++) {
            if (derivatives.swaps[i].state == 1) {
                count++;
            }
        }
        return count;
    };

    const assertMiltonDerivativeItem = async (
        testData,
        asset,
        swapId,
        direction,
        expectedIdsIndex,
        expectedUserDerivativeIdsIndex
    ) => {
        let actualDerivativeItem = null;
        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            if (direction == 0) {
                actualDerivativeItem = await testData.miltonStorageUsdt.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem = await testData.miltonStorageUsdt.getSwapReceiveFixed(swapId);
            }
        }
        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            if (direction == 0) {
                actualDerivativeItem = await testData.miltonStorageUsdc.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem = await testData.miltonStorageUsdc.getSwapReceiveFixed(swapId);
            }
        }
        if (testData.tokenDai && asset === testData.tokenDai.address) {
            if (direction == 0) {
                actualDerivativeItem = await testData.miltonStorageDai.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem = await testData.miltonStorageDai.getSwapReceiveFixed(swapId);
            }
        }

        expect(
            BigInt(expectedUserDerivativeIdsIndex),
            `Incorrect idsIndex for swap id ${actualDerivativeItem.id} actual: ${actualDerivativeItem.idsIndex}, expected: ${expectedUserDerivativeIdsIndex}`
        ).to.be.eq(BigInt(actualDerivativeItem.idsIndex));
    };

    const testCaseWhenMiltonEarnAndUserLost = async function (
        testData,
        asset,
        leverage,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        toleratedQuoteValue,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        expectedIncomeFeeValueWad,
        expectedPositionValue,
        expectedPositionValueWad
    ) {
        let expectedPositionValueWadAbs = expectedPositionValueWad;
        let expectedPositionValueAbs = expectedPositionValue;

        if (expectedPositionValueWad < 0) {
            expectedPositionValueWadAbs = -expectedPositionValueWadAbs;
            expectedPositionValueAbs = -expectedPositionValueAbs;
        }

        let miltonBalanceBeforePayout = null;
        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        let openerUserLost = null;
        let openerUserEarned = null;
        let closerUserLost = null;
        let closerUserEarned = null;
        let expectedOpenerUserUnderlyingTokenBalanceAfterClose = null;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose = null;
        let expectedMiltonUnderlyingTokenBalance = null;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad +
            TC_OPENING_FEE_18DEC +
            expectedPositionValueWadAbs -
            expectedIncomeFeeValueWad;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC +
                expectedPositionValueAbs;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_10MLN_18DEC + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_10MLN_18DEC + closerUserEarned - closerUserLost;
            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                expectedPositionValueAbs;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
            openerUserLost =
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC +
                expectedPositionValueAbs;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + closerUserEarned - closerUserLost;
            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_6DEC +
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                expectedPositionValueAbs;
        }

        await exetuceCloseSwapTestCase(
            testData,
            asset,
            leverage,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenSwap,
            iporValueAfterOpenSwap,
            toleratedQuoteValue,
            periodOfTimeElapsedInSeconds,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterClose,
            expectedCloserUserUnderlyingTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalanceWad,
            expectedOpenedPositions,
            expectedDerivativesTotalBalanceWad,
            expectedLiquidationDepositTotalBalanceWad,
            expectedTreasuryTotalBalanceWad,
            expectedSoap,
            openTimestamp,
            expectedPositionValueWad,
            expectedIncomeFeeValueWad
        );
    };

    const testCaseWhenMiltonLostAndUserEarn = async function (
        testData,
        asset,
        leverage,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        toleratedQuoteValue,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        expectedIncomeFeeValue,
        expectedIncomeFeeValueWad,
        expectedPositionValue,
        expectedPositionValueWad
    ) {
        let expectedPositionValueWadAbs = expectedPositionValueWad;
        let expectedPositionValueAbs = expectedPositionValue;

        if (expectedPositionValueWad < 0) {
            expectedPositionValueWadAbs = -expectedPositionValueWadAbs;
            expectedPositionValueAbs = -expectedPositionValueAbs;
        }

        let miltonBalanceBeforePayout = null;
        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        let closerUserEarned = null;
        let openerUserLost = null;
        let closerUserLost = null;
        let openerUserEarned = null;
        let expectedMiltonUnderlyingTokenBalance = null;
        let expectedOpenerUserUnderlyingTokenBalanceAfterClose = null;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose = null;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad - expectedPositionValueWadAbs + TC_OPENING_FEE_18DEC;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
                expectedPositionValueAbs +
                expectedIncomeFeeValue;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC -
                expectedPositionValueAbs +
                expectedIncomeFeeValue;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_10MLN_18DEC + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_10MLN_18DEC + closerUserEarned - closerUserLost;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
            openerUserLost =
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC -
                expectedPositionValueAbs +
                expectedIncomeFeeValue;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_6DEC +
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC -
                expectedPositionValueAbs +
                expectedIncomeFeeValue;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + closerUserEarned - closerUserLost;
        }
        expectedPositionValue = expectedPositionValueWad;
        await exetuceCloseSwapTestCase(
            testData,
            asset,
            leverage,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenSwap,
            iporValueAfterOpenSwap,
            toleratedQuoteValue,
            periodOfTimeElapsedInSeconds,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterClose,
            expectedCloserUserUnderlyingTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalanceWad,
            expectedOpenedPositions,
            expectedDerivativesTotalBalanceWad,
            expectedLiquidationDepositTotalBalanceWad,
            expectedTreasuryTotalBalanceWad,
            expectedSoap,
            openTimestamp,
            expectedPositionValueWad,
            expectedIncomeFeeValueWad
        );
    };

    const testCaseWhenUserClosesPositions = async function (
        testData,
        asset,
        leverage,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        periodOfTimeElapsedInSeconds,
        providedLiquidityAmount,
        numberOfSwapsToBeCreated,
        closeCallback,
        openTimestamp,
        pauseMilton
    ) {
        await executeCloseSwapsTestCase(
            testData,
            asset,
            leverage,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenSwap,
            iporValueAfterOpenSwap,
            periodOfTimeElapsedInSeconds,
            providedLiquidityAmount,
            numberOfSwapsToBeCreated,
            closeCallback,
            openTimestamp,
            pauseMilton
        );
    };

    const exetuceCloseSwapTestCase = async function (
        testData,
        asset,
        leverage,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        toleratedQuoteValue,
        periodOfTimeElapsedInSeconds,
        providedLiquidityAmount,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
        expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalanceWad,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        expectedPositionValue,
        expectedIncomeFeeValue
    ) {
        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }

        let totalAmount = null;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            totalAmount = TC_TOTAL_AMOUNT_10_000_18DEC;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            totalAmount = USD_10_000_6DEC;
        }

        const params = {
            asset: asset,
            totalAmount: totalAmount,
            toleratedQuoteValue: toleratedQuoteValue,
            leverage: leverage,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUser,
        };

        if (providedLiquidityAmount != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
                await testData.josephUsdt
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
            }
            if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
                await testData.josephUsdc
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
            }
            if (testData.tokenDai && params.asset === testData.tokenDai.address) {
                await testData.josephDai
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
            }
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueBeforeOpenSwap, params.openTimestamp);
        if (params.direction == 0) {
            await openSwapPayFixed(testData, params);
        } else if (params.direction == 1) {
            await openSwapReceiveFixed(testData, params);
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueAfterOpenSwap, params.openTimestamp);

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;

        let actualPositionValue = null;
        let actualIncomeFeeValue = null;

        //when
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            if (params.direction == 0) {
                actualPositionValue = await testData.miltonUsdt
                    .connect(params.from)
                    .itfCalculateSwapPayFixedValue(endTimestamp, 1);
                await testData.miltonUsdt.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                actualPositionValue = await testData.miltonUsdt
                    .connect(params.from)
                    .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

                await testData.miltonUsdt
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
            actualIncomeFeeValue = await testData.miltonUsdt
                .connect(params.from)
                .itfCalculateIncomeFeeValue(actualPositionValue);
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            if (params.direction == 0) {
                actualPositionValue = await testData.miltonUsdc
                    .connect(params.from)
                    .itfCalculateSwapPayFixedValue(endTimestamp, 1);
                await testData.miltonUsdc.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                actualPositionValue = await testData.miltonUsdc
                    .connect(params.from)
                    .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

                await testData.miltonUsdc
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
            actualIncomeFeeValue = await testData.miltonUsdc
                .connect(params.from)
                .itfCalculateIncomeFeeValue(actualPositionValue);
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            if (params.direction == 0) {
                actualPositionValue = await testData.miltonDai
                    .connect(params.from)
                    .itfCalculateSwapPayFixedValue(endTimestamp, 1);

                await testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                actualPositionValue = await testData.miltonDai
                    .connect(params.from)
                    .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

                await testData.miltonDai
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
            actualIncomeFeeValue = await testData.miltonDai
                .connect(params.from)
                .itfCalculateIncomeFeeValue(actualPositionValue);
        }

        expect(actualPositionValue, "Incorrect position value").to.be.eq(expectedPositionValue);
        expect(actualIncomeFeeValue, "Incorrect income fee value").to.be.eq(expectedIncomeFeeValue);

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            params.direction,
            openerUser,
            closerUser,
            providedLiquidityAmount,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
            expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalanceWad,
            expectedOpenedPositions,
            expectedDerivativesTotalBalanceWad,
            expectedLiquidationDepositTotalBalanceWad,
            expectedTreasuryTotalBalanceWad
        );

        const soapParams = {
            asset: params.asset,
            calculateTimestamp: endTimestamp,
            expectedSoap: expectedSoap,
            from: openerUser,
        };
        await assertSoap(testData, soapParams);
    };

    const executeCloseSwapsTestCase = async function (
        testData,
        asset,
        leverage,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        periodOfTimeElapsedInSeconds,
        providedLiquidityAmount,
        swapsToCreate,
        closeCallback,
        openTimestamp,
        pauseMilton
    ) {
        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }

        let totalAmount = null;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            totalAmount = TC_TOTAL_AMOUNT_10_000_18DEC;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            totalAmount = USD_10_000_6DEC;
        }

        const params = {
            asset: asset,
            totalAmount: totalAmount,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: leverage,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUser,
        };

        if (providedLiquidityAmount != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
                await testData.josephUsdt
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
            }
            if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
                await testData.josephUsdc
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
            }
            if (testData.tokenDai && params.asset === testData.tokenDai.address) {
                await testData.josephDai
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
            }
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueBeforeOpenSwap, params.openTimestamp);

        for (let i = 0; i < swapsToCreate; i++) {
            if (params.direction === 0) {
                await openSwapPayFixed(testData, params);
            } else if (params.direction === 1) {
                await openSwapReceiveFixed(testData, params);
            }
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, iporValueAfterOpenSwap, params.openTimestamp);

        //when
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            if (pauseMilton) {
                await testData.miltonUsdt.connect(admin).pause();
            }
            await closeCallback(testData.miltonUsdt.connect(closerUser));
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            if (pauseMilton) {
                await testData.miltonUsdc.connect(admin).pause();
            }
            await closeCallback(testData.miltonUsdc.connect(closerUser));
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            if (pauseMilton) {
                await testData.miltonDai.connect(admin).pause();
            }
            await closeCallback(testData.miltonDai.connect(closerUser));
        }
    };

    const assertExpectedValues = async function (
        testData,
        asset,
        direction,
        openerUser,
        closerUser,
        miltonBalanceBeforePayout,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
        expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalanceWad,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad
    ) {
        let actualDerivatives = null;
        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            if (direction == 0) {
                actualDerivatives = await testData.miltonStorageUsdt.getSwapsPayFixed(
                    openerUser.address,
                    0,
                    50
                );
            }
            if (direction == 1) {
                actualDerivatives = await testData.miltonStorageUsdt.getSwapsReceiveFixed(
                    openerUser.address,
                    0,
                    50
                );
            }
        }

        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            if (direction == 0) {
                actualDerivatives = await testData.miltonStorageUsdc.getSwapsPayFixed(
                    openerUser.address,
                    0,
                    50
                );
            }
            if (direction == 1) {
                actualDerivatives = await testData.miltonStorageUsdc.getSwapsReceiveFixed(
                    openerUser.address,
                    0,
                    50
                );
            }
        }

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            if (direction == 0) {
                actualDerivatives = await testData.miltonStorageDai.getSwapsPayFixed(
                    openerUser.address,
                    0,
                    50
                );
            }
            if (direction == 1) {
                actualDerivatives = await testData.miltonStorageDai.getSwapsReceiveFixed(
                    openerUser.address,
                    0,
                    50
                );
            }
        }

        let actualOpenSwapsVol = countOpenSwaps(actualDerivatives);

        expect(
            expectedOpenedPositions,
            `Incorrect number of opened derivatives, actual:  ${actualOpenSwapsVol}, expected: ${expectedOpenedPositions}`
        ).to.be.eq(actualOpenSwapsVol);

        let expectedOpeningFeeTotalBalanceWad = TC_OPENING_FEE_18DEC;
        let expectedPublicationFeeTotalBalanceWad = USD_10_18DEC;
        let openerUserUnderlyingTokenBalanceBeforePayout = null;
        let closerUserUnderlyingTokenBalanceBeforePayout = null;
        let miltonUnderlyingTokenBalanceAfterPayout = null;
        let openerUserUnderlyingTokenBalanceAfterPayout = null;
        let closerUserUnderlyingTokenBalanceAfterPayout = null;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            openerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_18DEC;
            closerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_18DEC;

            miltonUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(testData.miltonDai.address)
            );
            openerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(openerUser.address)
            );
            closerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(closerUser.address)
            );
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            openerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_6DEC;
            closerUserUnderlyingTokenBalanceBeforePayout = USD_10_000_000_6DEC;
            miltonUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(testData.miltonUsdt.address)
            );
            openerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(openerUser.address)
            );
            closerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(closerUser.address)
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
            expectedOpeningFeeTotalBalanceWad,
            expectedLiquidationDepositTotalBalanceWad,
            expectedPublicationFeeTotalBalanceWad,
            expectedLiquidityPoolTotalBalanceWad,
            expectedTreasuryTotalBalanceWad
        );

        let expectedSumOfBalancesBeforePayout = null;
        let actualSumOfBalances = null;

        if (openerUser.address === closerUser.address) {
            expectedSumOfBalancesBeforePayout =
                miltonBalanceBeforePayout + openerUserUnderlyingTokenBalanceBeforePayout;
            actualSumOfBalances =
                openerUserUnderlyingTokenBalanceAfterPayout +
                miltonUnderlyingTokenBalanceAfterPayout;
        } else {
            expectedSumOfBalancesBeforePayout =
                miltonBalanceBeforePayout +
                openerUserUnderlyingTokenBalanceBeforePayout +
                closerUserUnderlyingTokenBalanceBeforePayout;
            actualSumOfBalances =
                openerUserUnderlyingTokenBalanceAfterPayout +
                closerUserUnderlyingTokenBalanceAfterPayout +
                miltonUnderlyingTokenBalanceAfterPayout;
        }

        expect(
            expectedSumOfBalancesBeforePayout,
            `Incorrect balance between AMM Balance and Users Balance for asset ${asset}, actual: ${actualSumOfBalances}, expected ${expectedSumOfBalancesBeforePayout}`
        ).to.be.eql(actualSumOfBalances);
    };

    const assertSoap = async (testData, params) => {
        let actualSoapStruct = await calculateSoap(testData, params);
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then
        expect(
            params.expectedSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`
        ).to.be.eql(actualSoap);
    };

    const assertBalances = async (
        testData,
        asset,
        openerUser,
        closerUser,
        expectedOpenerUserUnderlyingTokenBalance,
        expectedCloserUserUnderlyingTokenBalance,
        expectedMiltonUnderlyingTokenBalance,
        expectedDerivativesTotalBalanceWad,
        expectedOpeningFeeTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedPublicationFeeTotalBalanceWad,
        expectedLiquidityPoolTotalBalanceWad,
        expectedTreasuryTotalBalanceWad
    ) => {
        let actualOpenerUserUnderlyingTokenBalance = null;
        let actualCloserUserUnderlyingTokenBalance = null;
        let balance = null;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            actualOpenerUserUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(openerUser.address)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(closerUser.address)
            );
            balance = await testData.miltonStorageDai.getExtendedBalance();
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            actualOpenerUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(openerUser.address)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(closerUser.address)
            );
            balance = await testData.miltonStorageUsdt.getExtendedBalance();
        }

        let actualMiltonUnderlyingTokenBalance = null;
        if (testData.tokenDai && asset === testData.tokenDai.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(testData.miltonDai.address)
            );
        }
        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(testData.miltonUsdt.address)
            );
        }
        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdc.balanceOf(testData.miltonUsdc.address)
            );
        }

        const actualPayFixedDerivativesBalance = BigInt(balance.payFixedSwaps);
        const actualRecFixedDerivativesBalance = BigInt(balance.receiveFixedSwaps);
        const actualDerivativesTotalBalance =
            actualPayFixedDerivativesBalance + actualRecFixedDerivativesBalance;
        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidationDepositTotalBalance = BigInt(balance.liquidationDeposit);
        const actualPublicationFeeTotalBalance = BigInt(balance.iporPublicationFee);
        const actualLiquidityPoolTotalBalanceWad = BigInt(balance.liquidityPool);
        const actualTreasuryTotalBalanceWad = BigInt(balance.treasury);

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

        if (expectedOpeningFeeTotalBalanceWad != null) {
            expect(
                expectedOpeningFeeTotalBalanceWad,
                `Incorrect opening fee total balance for ${asset}, actual:  ${actualOpeningFeeTotalBalance}, expected: ${expectedOpeningFeeTotalBalanceWad}`
            ).to.be.eq(actualOpeningFeeTotalBalance);
        }

        if (expectedLiquidationDepositTotalBalanceWad !== null) {
            expect(
                expectedLiquidationDepositTotalBalanceWad,
                `Incorrect liquidation deposit fee total balance for ${asset}, actual:  ${actualLiquidationDepositTotalBalance}, expected: ${expectedLiquidationDepositTotalBalanceWad}`
            ).to.be.eq(actualLiquidationDepositTotalBalance);
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
});

//TODO: add test where open Position Pay Fixed and EMA > Ipor
//TODO: add test where open Position Pay Fixed and EMA < Ipor
//TODO: add test where open Position Rec Fixed and EMA > Ipor
//TODO: add test where open Position Rec Fixed and EMA < Ipor

//TODO: add test when spread is calculated 1 pay fixed 0 rec fixed, 0 pay fixed 1 rec fixed

//TODO: !!!! add test when before open position liquidity pool is empty and opening fee is zero - then spread cannot be calculated in correct way!!!

//TODO: !!!! add test when closing swap, Milton lost, Trader earn, but milton don't have enough balance to withdraw during closing position

//TODO: check initial IBT

//TODO: add test: open long, change index, open short, change index, close long and short and check if soap = 0

//TODO: test when ipor not ready yet

//TODO: create test when ipor index not yet created for specific asset

//TODO: add test where total amount higher than openingfeeamount

//TODO: add test which checks emited events!!!

//TODO: add test when user try to send eth on milton

//TODO: add tests for pausable methods
//TODO: !!! test when close position, trader earn more than Milton hase in ERC20 tokens
