const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_365_18DEC,
    USD_10_18DEC,
    USD_20_18DEC,
    USD_10_000_18DEC,
    USD_10_000_6DEC,
    USD_28_000_18DEC,
    USD_28_000_6DEC,
    TC_COLLATERAL_18DEC,
    USD_10_000_000_6DEC,

    USD_10_000_000_18DEC,
    TC_OPENING_FEE_6DEC,
    TC_OPENING_FEE_18DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_6DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_6DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    ZERO,
    SPECIFIC_INTEREST_AMOUNT_CASE_1,
    SPECIFIC_INCOME_TAX_CASE_1,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
    TC_INCOME_TAX_18DEC,
    TC_COLLATERAL_6DEC,
} = require("./Const.js");

const {
    assertError,
    getLibraries,
    getStandardDerivativeParamsDAI,
    getStandardDerivativeParamsUSDT,
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("Milton", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let libraries;

    before(async () => {
        libraries = await getLibraries();
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(libraries, [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
        ]);
    });

    it("should NOT open position because collateral amount too low", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const collateral = 0;
        const slippageValue = 3;
        const collateralizationFactor = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);
        await assertError(
            //when
            testData.miltonDai.itfOpenSwapPayFixed(
                timestamp,
                collateral,
                slippageValue,
                collateralizationFactor
            ),
            //then
            "IPOR_4"
        );
    });

    it("should NOT open position because slippage too low", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const collateral = BigInt("30000000000000000001");
        const slippageValue = 0;
        const collateralizationFactor = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);
        await assertError(
            //when
            testData.miltonDai.itfOpenSwapPayFixed(
                timestamp,
                collateral,
                slippageValue,
                collateralizationFactor
            ),
            //then
            "IPOR_5"
        );
    });

    it("should NOT open position because slippage too high - 18 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const collateral = BigInt("30000000000000000001");
        const slippageValue = BigInt("100000000000000000001");
        const collateralizationFactor = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            testData.miltonDai.itfOpenSwapPayFixed(
                timestamp,
                collateral,
                slippageValue,
                collateralizationFactor
            ),
            //then
            "IPOR_9"
        );
    });

    it("should NOT open position because slippage too high - 6 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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

        const collateral = BigInt("30000001");
        const slippageValue = BigInt("100000000000000000001");
        const collateralizationFactor = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            testData.miltonUsdt.itfOpenSwapPayFixed(
                timestamp,
                collateral,
                slippageValue,
                collateralizationFactor
            ),
            //then
            "IPOR_9"
        );
    });

    it("should NOT open position because collateral amount too high", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const collateral = BigInt("1000000000000000000000001");
        const slippageValue = 3;
        const collateralizationFactor = BigInt(10000000000000000000);
        const timestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            testData.miltonDai.itfOpenSwapPayFixed(
                timestamp,
                collateral,
                slippageValue,
                collateralizationFactor
            ),
            //then
            "IPOR_10"
        );
    });

    it("should open pay fixed position - simple case DAI - 18 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let collateralWad = TC_COLLATERAL_18DEC;
        let openingFee = TC_OPENING_FEE_18DEC;

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad + params.totalAmount;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee;
        let expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
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
                await testData.miltonStorageDai.getBalance()
            ).payFixedSwaps
        );
        const actualRecFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonStorageDai.getBalance()
            ).receiveFixedSwaps
        );
        const actualDerivativesTotalBalanceWad =
            actualPayFixDerivativesBalanceWad +
            actualRecFixDerivativesBalanceWad;

        expect(
            expectedDerivativesTotalBalanceWad,
            `Incorrect derivatives total balance for ${params.asset} actual ${actualDerivativesTotalBalanceWad}, expected ${expectedDerivativesTotalBalanceWad}Wad`
        ).to.be.eq(actualDerivativesTotalBalanceWad);
    });

    it("should open pay fixed position - simple case USDT - 6 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let miltonBalanceBeforePayout = USD_28_000_6DEC;
        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                miltonBalanceBeforePayout,
                params.openTimestamp
            );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayout + params.totalAmount;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee;
        let expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await testData.miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
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
                await testData.miltonStorageUsdt.getBalance()
            ).payFixedSwaps
        );

        const actualRecFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonStorageUsdt.getBalance()
            ).receiveFixedSwaps
        );

        const actualDerivativesTotalBalanceWad =
            actualPayFixDerivativesBalanceWad +
            actualRecFixDerivativesBalanceWad;

        expect(
            expectedDerivativesTotalBalanceWad,
            `Incorrect derivatives total balance for ${params.asset} actual ${actualDerivativesTotalBalanceWad}, expected ${expectedDerivativesTotalBalanceWad}Wad`
        ).to.be.eq(actualDerivativesTotalBalanceWad);
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        let liquidationDepositAmount = USD_20_18DEC;

        let expectedIncomeTaxValue = BigInt("0");
        let expectedIncomeTaxValueWad = BigInt("0");

        let totalAmount = USD_10_000_18DEC;
        let collateral = TC_COLLATERAL_18DEC;
        let openingFee = TC_OPENING_FEE_18DEC;

        let diffAfterClose =
            totalAmount - collateral - liquidationDepositAmount;

        let expectedOpenerUserUnderlyingTokenBalanceAfterPayOut =
            USER_SUPPLY_10MLN_18DEC - diffAfterClose;
        let expectedCloserUserUnderlyingTokenBalanceAfterPayOut =
            USER_SUPPLY_10MLN_18DEC - diffAfterClose;

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad + diffAfterClose;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee - expectedIncomeTaxValue;

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
            0,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
            expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalanceWad,
            0,
            ZERO,
            ZERO,
            expectedIncomeTaxValue,
            ZERO,
            null,
            expectedPositionValue,
            expectedIncomeTaxValue
        );
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValueWad = BigInt("6826719107555404611");
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

    it("should close position, USDT, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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

        let expectedIncomeTaxValueWad = BigInt("6826719107555404611");
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

    it("should NOT open position because Liquidity Pool balance is to low", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: BigInt("10000000000000000000000"), //10 000 USD
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        let closeSwapTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                BigInt("10000000000000000"),
                params.openTimestamp
            );

        await openSwapPayFixed(testData, params);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                BigInt("1600000000000000000"),
                params.openTimestamp
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                BigInt("50000000000000000"),
                closeSwapTimestamp
            );

        await testData.miltonStorageDai.setJoseph(userOne.address);

        await testData.miltonStorageDai
            .connect(userOne)
            .subtractLiquidity(BigInt("20000000000000000000000"));

        await testData.miltonStorageDai.setJoseph(testData.josephDai.address);

        //when
        await assertError(
            //when
            testData.miltonDai
                .connect(userTwo)
                .itfCloseSwapPayFixed(1, closeSwapTimestamp),
            //then
            "IPOR_14"
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Collateral, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost > Collateral, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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

        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValueWad = BigInt("791899416476426938347");
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

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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

        let expectedIncomeTaxValueWad = BigInt("791899416476426938347");
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

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValueWad = BigInt("856889782380354383694");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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

        let expectedIncomeTaxValue = BigInt("996700990");
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("778245978261316123526");
        let expectedIncomeTaxValueWad = BigInt("778245978261316123526");

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

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
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

        let expectedIncomeTaxValue = BigInt("778245978");
        let expectedIncomeTaxValueWad = BigInt("778245978261316123526");
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

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = SPECIFIC_INCOME_TAX_CASE_1;
        let expectedIncomeTaxValueWad = SPECIFIC_INCOME_TAX_CASE_1;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_5_18DEC,
                params.openTimestamp
            );
        await openSwapPayFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_120_18DEC,
                params.openTimestamp
            );
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai
                .connect(userThree)
                .itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("636796358352768143662");
        let expectedIncomeTaxValueWad = BigInt("636796358352768143662");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_120_18DEC,
                params.openTimestamp
            );
        await openSwapPayFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_5_18DEC,
                params.openTimestamp
            );
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai
                .connect(userThree)
                .itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("856889782380354383694");
        let expectedIncomeTaxValueWad = BigInt("856889782380354383694");
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
            PERIOD_50_DAYS_IN_SECONDS,
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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price not changed, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("6826719107555402563");
        let expectedIncomeTaxValueWad = BigInt("6826719107555402563");
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

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price changed 25%, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValueWad = BigInt("6826719107555404611");
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

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("279895483409771589481");
        let expectedIncomeTaxValueWad = BigInt("279895483409771589481");
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

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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

    it("should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("791899416476426932749");
        let expectedIncomeTaxValueWad = BigInt("791899416476426932749");
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

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("841597931579430277365");
        let expectedIncomeTaxValueWad = BigInt("841597931579430277365");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("652088209153692249992");
        let expectedIncomeTaxValueWad = BigInt("652088209153692249992");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_120_18DEC,
                params.openTimestamp
            );
        await openSwapReceiveFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_5_18DEC,
                params.openTimestamp
            );
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai
                .connect(userThree)
                .itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_5_18DEC,
                params.openTimestamp
            );
        await openSwapReceiveFixed(testData, params);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_120_18DEC,
                params.openTimestamp
            );
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            testData.miltonDai
                .connect(userThree)
                .itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("841597931579430277365");
        let expectedIncomeTaxValueWad = BigInt("841597931579430277365");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("652088209153692249992");
        let expectedIncomeTaxValueWad = BigInt("652088209153692249992");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = TC_INCOME_TAX_18DEC;
        let expectedIncomeTaxValueWad = TC_INCOME_TAX_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should NOT close position, because incorrect swap Id", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
                USD_28_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        await assertError(
            //when
            testData.miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(
                    0,
                    openTimestamp + PERIOD_25_DAYS_IN_SECONDS
                ),
            //then
            "IPOR_22"
        );
    });

    it("should NOT close position, because swap has incorrect status - pay fixed", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);

        const endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapPayFixed(1, endTimestamp);

        await assertError(
            //when
            testData.miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(1, endTimestamp),
            //then
            "IPOR_23"
        );
    });

    it("should NOT close position, because swap has incorrect status - receive fixed", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const openerUser = userTwo;
        const closerUser = userTwo;
        const iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        const openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openSwapReceiveFixed(testData, derivativeParams25days);

        const endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapReceiveFixed(1, endTimestamp);

        await assertError(
            //when
            testData.miltonDai
                .connect(closerUser)
                .itfCloseSwapReceiveFixed(1, endTimestamp),
            //then
            "IPOR_23"
        );
    });

    it("should NOT close position, because swap not exists", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        let closerUser = userTwo;
        let openTimestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            testData.miltonDai
                .connect(closerUser)
                .itfCloseSwapPayFixed(
                    0,
                    openTimestamp + PERIOD_25_DAYS_IN_SECONDS
                ),
            //then
            "IPOR_22"
        );
    });

    it("should close only one position - close first position", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);
        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(2);

        //when
        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapPayFixed(1, endTimestamp);

        //then
        let actualDerivatives =
            await testData.miltonStorageDai.getSwapsPayFixed(
                derivativeParams25days.from.address
            );
        let actualOpenedPositionsVol = countOpenSwaps(actualDerivatives);

        expect(
            expectedOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`
        ).to.be.eq(actualOpenedPositionsVol);

        let oneDerivative = actualDerivatives[0];

        expect(
            expectedDerivativeId,
            `Incorrect swap id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`
        ).to.be.eq(BigInt(oneDerivative.id));
    });

    it("should close only one position - close last position", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openSwapPayFixed(testData, derivativeParams25days);
        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(1);

        //when
        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapPayFixed(2, endTimestamp);

        //then
        let actualDerivatives =
            await testData.miltonStorageDai.getSwapsPayFixed(
                derivativeParams25days.from.address
            );
        let actualOpenedPositionsVol = countOpenSwaps(actualDerivatives);

        expect(
            expectedOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`
        ).to.be.eq(actualOpenedPositionsVol);

        let oneDerivative = actualDerivatives[0];

        expect(
            expectedDerivativeId,
            `Incorrect swap id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`
        ).to.be.eq(BigInt(oneDerivative.id));
    });

    it("should close position with appropriate balance, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity, IPOR index calculated before close", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let expectedIncomeTaxValue = BigInt("636796358352768143662");
        let expectedPositionValue = BigInt("6367963583527681436620");
        let collateralizationFactor = USD_10_18DEC;
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_5_18DEC;
        let iporValueAfterOpenSwap = PERCENTAGE_50_18DEC;
        let periodOfTimeElapsedInSeconds = PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositions = 0;
        let expectedDerivativesTotalBalanceWad = ZERO;
        let expectedLiquidationDepositTotalBalanceWad = ZERO;
        let expectedTreasuryTotalBalanceWad = expectedIncomeTaxValue;
        let expectedSoap = ZERO;
        let openTimestamp = null;

        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;

        let closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        let openerUserLost =
            TC_OPENING_FEE_18DEC +
            TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
            expectedPositionValue +
            expectedIncomeTaxValue;

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
            expectedIncomeTaxValue;

        let expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC + openerUserEarned - openerUserLost;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_10MLN_18DEC + closerUserEarned - closerUserLost;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad -
            expectedPositionValue +
            TC_OPENING_FEE_18DEC;

        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }
        const params = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: collateralizationFactor,
            openTimestamp: localOpenTimestamp,
            from: openerUser,
        };

        if (miltonBalanceBeforePayoutWad != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await testData.josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(
                    miltonBalanceBeforePayoutWad,
                    params.openTimestamp
                );
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                iporValueBeforeOpenSwap,
                params.openTimestamp
            );
        await openSwapPayFixed(testData, params);
        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                iporValueAfterOpenSwap,
                params.openTimestamp
            );

        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                iporValueAfterOpenSwap,
                endTimestamp - 1
            );

        //additional check for position value and for incomeTax value
        const actualPositionValue = await testData.miltonDai
            .connect(params.from)
            .itfCalculateSwapPayFixedValue(endTimestamp, 1);

        const actualIncomeTaxValue = await testData.miltonDai
            .connect(params.from)
            .itfCalculateIncomeTaxValue(actualPositionValue);

        expect(actualPositionValue, "Incorrect position value").to.be.eq(
            expectedPositionValue
        );
        expect(actualIncomeTaxValue, "Incorrect income tax value").to.be.eq(
            expectedIncomeTaxValue
        );

        //when
        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapPayFixed(1, endTimestamp);

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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
            .itfProvideLiquidity(
                BigInt(3) * USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );

        //when
        await openSwapPayFixed(testData, derivativeParams);
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openSwapPayFixed(testData, derivativeParams);
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openSwapPayFixed(testData, derivativeParams);

        //then
        let actualUserDerivativeIds =
            await testData.miltonStorageDai.getSwapPayFixedIds(
                openerUser.address
            );

        expect(
            expectedUserDerivativeIdsLength,
            `Incorrect user swap ids length actual: ${actualUserDerivativeIds.length}, expected: ${expectedUserDerivativeIdsLength}`
        ).to.be.eq(actualUserDerivativeIds.length);

        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            1,
            0,
            0,
            0
        );
        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            2,
            0,
            1,
            1
        );
        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            3,
            0,
            2,
            2
        );
    });

    it("should open many positions and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
            .itfProvideLiquidity(
                BigInt(3) * USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );

        //when
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(
                userThree.address
            );

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);

        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            1,
            0,
            0,
            0
        );
        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            2,
            0,
            1,
            0
        );
        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            3,
            0,
            2,
            1
        );
    });

    it("should open many positions and close one position and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
            .itfProvideLiquidity(
                BigInt(3) * USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(
                2,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(
                userThree.address
            );

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);

        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            1,
            0,
            0,
            0
        );
        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            3,
            0,
            1,
            1
        );
    });

    it("should open many positions and close two positions and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
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
            .itfProvideLiquidity(
                BigInt(3) * USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(
                2,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );
        await testData.miltonDai
            .connect(userTwo)
            .itfCloseSwapPayFixed(
                3,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(
                userThree.address
            );

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);

        await assertMiltonDerivativeItem(
            testData,
            derivativeParams.asset,
            1,
            0,
            0,
            0
        );
    });

    //TODO: debug case where SoapIndicatorStorage.quasiHypotheticalInterestCumulative is changed to uint128
    it("should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt(2) * USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );
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
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openSwapPayFixed(testData, derivativeParams);

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(
                1,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(
                2,
                derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);

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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt(2) * USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );
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
            .itfCloseSwapPayFixed(
                1,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(
                2,
                derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);

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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt(2) * USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );
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
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openSwapPayFixed(testData, derivativeParams);

        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(
                1,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );

        //when
        await testData.miltonDai
            .connect(userThree)
            .itfCloseSwapPayFixed(
                2,
                derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorageDai.getSwapPayFixedIds(userTwo.address);

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user swap ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user swap ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
    });

    it("should calculate income tax, 5%, not owner, Milton loses, user earns, |I| < D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            2
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

        let expectedIncomeTaxValue = BigInt("420798965789715138682");
        let expectedIncomeTaxValueWad = BigInt("420798965789715138682");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should calculate income tax, 5%, Milton loses, user earns, |I| > D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            2
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

        let expectedIncomeTaxValue = BigInt("498350494851544536639");
        let expectedIncomeTaxValueWad = BigInt("498350494851544536639");

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

    it("should calculate income tax, 5%, Milton earns, user loses, |I| < D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            2
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

        let expectedIncomeTaxValue = BigInt("395949708238213469173");
        let expectedIncomeTaxValueWad = BigInt("395949708238213469173");
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

    it("should calculate income tax, 5%, Milton earns, user loses, |I| > D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            2
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

        let expectedIncomeTaxValue = BigInt("498350494851544536639");
        let expectedIncomeTaxValueWad = BigInt("498350494851544536639");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should calculate income tax, 100%, Milton loses, user earns, |I| < D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3
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

        let expectedIncomeTaxValue = BigInt("8415979315794302773646");
        let expectedIncomeTaxValueWad = BigInt("8415979315794302773646");
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should calculate income tax, 100%, Milton loses, user earns, |I| > D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3
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

        let expectedIncomeTaxValue = TC_COLLATERAL_18DEC;
        let expectedIncomeTaxValueWad = TC_COLLATERAL_18DEC;
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

    it("should calculate income tax, 100%, Milton earns, user loses, |I| < D, to low liquidity pool", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3
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

        let expectedIncomeTaxValue = BigInt("7918994164764269383465");
        let expectedIncomeTaxValueWad = BigInt("7918994164764269383465");
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

    it("should calculate income tax, 100%, Milton earns, user loses, |I| > D, to low liquidity pool", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            3
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

        let expectedIncomeTaxValue = TC_COLLATERAL_18DEC;
        let expectedIncomeTaxValueWad = TC_COLLATERAL_18DEC;
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
            PERIOD_50_DAYS_IN_SECONDS,
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

    it("should open pay fixed position, DAI, custom Opening Fee for Treasury 50%", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            4
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
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let expectedOpeningFeeTotalBalanceWad = TC_OPENING_FEE_18DEC;
        let expectedTreasuryTotalBalanceWad = BigInt("149505148455463361");

        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        let expectedLiquidityPoolTotalBalanceWad = BigInt(
            "28002840597820653803859"
        );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //then
        let balance = await testData.miltonStorageDai.getBalance();

        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidityPoolTotalBalanceWad = BigInt(
            balance.liquidityPool
        );
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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            5
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
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let expectedOpeningFeeTotalBalanceWad = TC_OPENING_FEE_18DEC;
        let expectedTreasuryTotalBalanceWad = BigInt("74752574227731681");

        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        let expectedLiquidityPoolTotalBalanceWad = BigInt(
            "28002915350394881535539"
        );
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //then
        let balance = await testData.miltonStorageDai.getBalance();

        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidityPoolTotalBalanceWad = BigInt(
            balance.liquidityPool
        );
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

    it("should NOT transfer Publication Fee to Charlie Treasury - caller not publication fee transferer", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //when
        await assertError(
            //when
            testData.miltonDai.transferPublicationFee(BigInt("100")),
            //then
            "IPOR_31"
        );
    });

    it("should NOT transfer Publication Fee to Charlie Treasury - Charlie Treasury address incorrect", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        await data.iporConfiguration.grantRole(
            keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"),
            admin.address
        );
        await data.iporConfiguration.grantRole(
            keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"),
            admin.address
        );

        await data.iporConfiguration.setMiltonPublicationFeeTransferer(
            admin.address
        );

        //when
        await assertError(
            //when
            testData.miltonDai.transferPublicationFee(BigInt("100")),
            //then
            "IPOR_29"
        );
    });

    it("should transfer Publication Fee to Charlie Treasury - simple case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("CHARLIE_TREASURER_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("CHARLIE_TREASURER_ROLE"),
            admin.address
        );
        await data.iporConfiguration.grantRole(
            keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"),
            admin.address
        );
        await data.iporConfiguration.grantRole(
            keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"),
            admin.address
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
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        await data.iporConfiguration.setMiltonPublicationFeeTransferer(
            admin.address
        );
        await testData.iporAssetConfigurationDai.setCharlieTreasurer(
            userThree.address
        );

        const transferedAmount = BigInt("100");

        //when
        await testData.miltonDai.transferPublicationFee(transferedAmount);

        //then
        let balance = await testData.miltonStorageDai.getBalance();

        let expectedErc20BalanceCharlieTreasurer =
            USER_SUPPLY_10MLN_18DEC + transferedAmount;
        let actualErc20BalanceCharlieTreasurer = BigInt(
            await testData.tokenDai.balanceOf(userThree.address)
        );

        let expectedErc20BalanceMilton =
            USD_28_000_18DEC + USD_10_000_18DEC - transferedAmount;
        let actualErc20BalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(testData.miltonDai.address)
        );

        let expectedPublicationFeeBalanceMilton =
            USD_10_18DEC - transferedAmount;
        const actualPublicationFeeBalanceMilton = BigInt(
            balance.iporPublicationFee
        );

        expect(
            expectedErc20BalanceCharlieTreasurer,
            `Incorrect ERC20 Charlie Treasurer balance for ${params.asset}, actual:  ${actualErc20BalanceCharlieTreasurer},
                expected: ${expectedErc20BalanceCharlieTreasurer}`
        ).to.be.eq(actualErc20BalanceCharlieTreasurer);

        expect(
            expectedErc20BalanceMilton,
            `Incorrect ERC20 Milton balance for ${params.asset}, actual:  ${actualErc20BalanceMilton},
                expected: ${expectedErc20BalanceMilton}`
        ).to.be.eq(actualErc20BalanceMilton);

        expect(
            expectedPublicationFeeBalanceMilton,
            `Incorrect Milton balance for ${params.asset}, actual:  ${actualPublicationFeeBalanceMilton},
                expected: ${expectedPublicationFeeBalanceMilton}`
        ).to.be.eq(actualPublicationFeeBalanceMilton);
    });

    it("should NOT open pay fixed position, DAI, collateralization factor too low", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt(500),
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await assertError(
            //when
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            //then
            "IPOR_12"
        );
    });

    it("should NOT open pay fixed position, DAI, collateralization factor too high", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt("1000000000000000000001"),
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await assertError(
            //when
            testData.miltonDai
                .connect(userTwo)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                ),
            //then
            "IPOR_34"
        );
    });

    it("should open pay fixed position, DAI, custom collateralization factor - simple case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt("15125000000000000000"),
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        //when
        await testData.miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );

        //then
        let actualDerivativeItem =
            await testData.miltonStorageDai.getSwapPayFixed(1);
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
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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

        let veryLongTimeAgoTimestamp = 31536000; //1971-01-01
        let expectedIncomeTaxValue = ZERO;
        let expectedIncomeTaxValueWad = ZERO;
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
            0,
            0,
            ZERO,
            ZERO,
            expectedIncomeTaxValueWad,
            ZERO,
            veryLongTimeAgoTimestamp,
            expectedIncomeTaxValueWad,
            expectedPositionValue,
            expectedPositionValueWad
        );
    });

    it("should calculate Pay Fixed Position Value - simple case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
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
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        let miltonBalanceBeforePayoutWad = USD_28_000_18DEC;
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );
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
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
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
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
    };

    const countOpenSwaps = (derivatives) => {
        let count = 0;
        for (let i = 0; i < derivatives.length; i++) {
            if (derivatives[i].state == 1) {
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
                actualDerivativeItem =
                    await testData.miltonStorageUsdt.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem =
                    await testData.miltonStorageUsdt.getSwapReceiveFixed(
                        swapId
                    );
            }
        }
        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            if (direction == 0) {
                actualDerivativeItem =
                    await testData.miltonStorageUsdc.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem =
                    await testData.miltonStorageUsdc.getSwapReceiveFixed(
                        swapId
                    );
            }
        }
        if (testData.tokenDai && asset === testData.tokenDai.address) {
            if (direction == 0) {
                actualDerivativeItem =
                    await testData.miltonStorageDai.getSwapPayFixed(swapId);
            }

            if (direction == 1) {
                actualDerivativeItem =
                    await testData.miltonStorageDai.getSwapReceiveFixed(swapId);
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
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        expectedIncomeTaxValueWad,
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
            expectedIncomeTaxValueWad;

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
            collateralizationFactor,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenSwap,
            iporValueAfterOpenSwap,
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
            expectedIncomeTaxValueWad
        );
    };

    const testCaseWhenMiltonLostAndUserEarn = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        expectedIncomeTaxValue,
        expectedIncomeTaxValueWad,
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
            miltonBalanceBeforePayoutWad -
            expectedPositionValueWadAbs +
            TC_OPENING_FEE_18DEC;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
                expectedPositionValueAbs +
                expectedIncomeTaxValue;

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
                expectedIncomeTaxValue;
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
                expectedIncomeTaxValue;

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
                expectedIncomeTaxValue;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + closerUserEarned - closerUserLost;
        }
        expectedPositionValue = expectedPositionValueWad;
        await exetuceCloseSwapTestCase(
            testData,
            asset,
            collateralizationFactor,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenSwap,
            iporValueAfterOpenSwap,
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
            expectedIncomeTaxValueWad
        );
    };

    const exetuceCloseSwapTestCase = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenSwap,
        iporValueAfterOpenSwap,
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
        expectedIncomeTaxValue
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
            totalAmount = USD_10_000_18DEC;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            totalAmount = USD_10_000_6DEC;
        }

        const params = {
            asset: asset,
            totalAmount: totalAmount,
            slippageValue: 3,
            collateralizationFactor: collateralizationFactor,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUser,
        };

        if (providedLiquidityAmount != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            if (
                testData.tokenUsdt &&
                params.asset === testData.tokenUsdt.address
            ) {
                await testData.josephUsdt
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(
                        providedLiquidityAmount,
                        params.openTimestamp
                    );
            }
            if (
                testData.tokenUsdc &&
                params.asset === testData.tokenUsdc.address
            ) {
                await testData.josephUsdc
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(
                        providedLiquidityAmount,
                        params.openTimestamp
                    );
            }
            if (
                testData.tokenDai &&
                params.asset === testData.tokenDai.address
            ) {
                await testData.josephDai
                    .connect(liquidityProvider)
                    .itfProvideLiquidity(
                        providedLiquidityAmount,
                        params.openTimestamp
                    );
            }
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                iporValueBeforeOpenSwap,
                params.openTimestamp
            );
        if (params.direction == 0) {
            await openSwapPayFixed(testData, params);
        } else if (params.direction == 1) {
            await openSwapReceiveFixed(testData, params);
        }

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                iporValueAfterOpenSwap,
                params.openTimestamp
            );

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;

        let actualPositionValue = null;
        let actualIncomeTaxValue = null;

        //when
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            if (params.direction == 0) {
                actualPositionValue = await testData.miltonUsdt
                    .connect(params.from)
                    .itfCalculateSwapPayFixedValue(endTimestamp, 1);
                await testData.miltonUsdt
                    .connect(closerUser)
                    .itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                actualPositionValue = await testData.miltonUsdt
                    .connect(params.from)
                    .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

                await testData.miltonUsdt
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
            actualIncomeTaxValue = await testData.miltonUsdt
                .connect(params.from)
                .itfCalculateIncomeTaxValue(actualPositionValue);
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            if (params.direction == 0) {
                actualPositionValue = await testData.miltonUsdc
                    .connect(params.from)
                    .itfCalculateSwapPayFixedValue(endTimestamp, 1);
                await testData.miltonUsdc
                    .connect(closerUser)
                    .itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                actualPositionValue = await testData.miltonUsdc
                    .connect(params.from)
                    .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

                await testData.miltonUsdc
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
            actualIncomeTaxValue = await testData.miltonUsdc
                .connect(params.from)
                .itfCalculateIncomeTaxValue(actualPositionValue);
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            if (params.direction == 0) {
                actualPositionValue = await testData.miltonDai
                    .connect(params.from)
                    .itfCalculateSwapPayFixedValue(endTimestamp, 1);

                await testData.miltonDai
                    .connect(closerUser)
                    .itfCloseSwapPayFixed(1, endTimestamp);
            } else if (params.direction == 1) {
                actualPositionValue = await testData.miltonDai
                    .connect(params.from)
                    .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

                await testData.miltonDai
                    .connect(closerUser)
                    .itfCloseSwapReceiveFixed(1, endTimestamp);
            }
            actualIncomeTaxValue = await testData.miltonDai
                .connect(params.from)
                .itfCalculateIncomeTaxValue(actualPositionValue);
        }

        expect(actualPositionValue, "Incorrect position value").to.be.eq(
            expectedPositionValue
        );
        expect(actualIncomeTaxValue, "Incorrect income tax value").to.be.eq(
            expectedIncomeTaxValue
        );

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
                actualDerivatives =
                    await testData.miltonStorageUsdt.getSwapsPayFixed(
                        openerUser.address
                    );
            }
            if (direction == 1) {
                actualDerivatives =
                    await testData.miltonStorageUsdt.getSwapsReceiveFixed(
                        openerUser.address
                    );
            }
        }

        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            if (direction == 0) {
                actualDerivatives =
                    await testData.miltonStorageUsdc.getSwapsPayFixed(
                        openerUser.address
                    );
            }
            if (direction == 1) {
                actualDerivatives =
                    await testData.miltonStorageUsdc.getSwapsReceiveFixed(
                        openerUser.address
                    );
            }
        }

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            if (direction == 0) {
                actualDerivatives =
                    await testData.miltonStorageDai.getSwapsPayFixed(
                        openerUser.address
                    );
            }
            if (direction == 1) {
                actualDerivatives =
                    await testData.miltonStorageDai.getSwapsReceiveFixed(
                        openerUser.address
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
                miltonBalanceBeforePayout +
                openerUserUnderlyingTokenBalanceBeforePayout;
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
            balance = await testData.miltonStorageDai.getBalance();
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            actualOpenerUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(openerUser.address)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(closerUser.address)
            );
            balance = await testData.miltonStorageUsdt.getBalance();
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
        const actualRecFixedDerivativesBalance = BigInt(
            balance.receiveFixedSwaps
        );
        const actualDerivativesTotalBalance =
            actualPayFixedDerivativesBalance + actualRecFixedDerivativesBalance;
        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidationDepositTotalBalance = BigInt(
            balance.liquidationDeposit
        );
        const actualPublicationFeeTotalBalance = BigInt(
            balance.iporPublicationFee
        );
        const actualLiquidityPoolTotalBalanceWad = BigInt(
            balance.liquidityPool
        );
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

//TODO: test when transfer ownership and Milton still works properly

//TODO: add test: open long, change index, open short, change index, close long and short and check if soap = 0

//TODO: test when ipor not ready yet

//TODO: create test when ipor index not yet created for specific asset

//TODO: add test where total amount higher than openingfeeamount

//TODO: add test which checks emited events!!!
//TODO: add test when warren address will change and check if milton see this
//TODO: add test when user try to send eth on milton
//TODO: add test where milton storage is changing - how balance behave
//TODO: add tests for pausable methods
