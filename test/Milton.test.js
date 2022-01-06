const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_18_DECIMALS,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_3_6DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_10_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_100_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_365_18DEC,
    USD_10_6DEC,
    USD_10_18DEC,
    USD_20_18DEC,
    USD_10_000_18DEC,
    USD_10_000_6DEC,
    USD_10_400_18DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
    USD_9063__63_18DEC,
    USD_10_000_000_6DEC,

    USD_10_000_000_18DEC,
    TC_OPENING_FEE_6DEC,
    TC_OPENING_FEE_18DEC,
    TC_COLLATERAL_6DEC,
    TC_COLLATERAL_18DEC,
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
    setupIpTokenDaiInitialValues,
    setupIpTokenUsdtInitialValues,
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

    it("should NOT open position because deposit amount too low", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        const asset = testData.tokenDai.address;
        const collateral = 0;
        const slippageValue = 3;
        const direction = 0;
        const collateralizationFactor = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);
        await assertError(
            //when
            data.milton.test_openPosition(
                timestamp,
                asset,
                collateral,
                slippageValue,
                collateralizationFactor,
                direction
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
            libraries
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

        const asset = testData.tokenDai.address;
        const collateral = BigInt("30000000000000000001");
        const slippageValue = 0;
        const direction = 0;
        const collateralizationFactor = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);
        await assertError(
            //when
            data.milton.test_openPosition(
                timestamp,
                asset,
                collateral,
                slippageValue,
                collateralizationFactor,
                direction
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
            libraries
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

        const asset = testData.tokenDai.address;
        const collateral = BigInt("30000000000000000001");
        const slippageValue = BigInt("100000000000000000001");
        const direction = 0;
        const collateralizationFactor = USD_10_18DEC;
        const timestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            data.milton.test_openPosition(
                timestamp,
                asset,
                collateral,
                slippageValue,
                collateralizationFactor,
                direction
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
            libraries
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

        const asset = testData.tokenUsdt.address;
        const collateral = BigInt("30000001");
        const slippageValue = BigInt("100000000000000000001");
        const direction = 0;
        const collateralizationFactor = USD_10_6DEC;
        const timestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            data.milton.test_openPosition(
                timestamp,
                asset,
                collateral,
                slippageValue,
                collateralizationFactor,
                direction
            ),
            //then
            "IPOR_9"
        );
    });

    it("should NOT open position because deposit amount too high", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        const asset = testData.tokenDai.address;
        const collateral = BigInt("1000000000000000000000001");
        const slippageValue = 3;
        const direction = 0;
        const collateralizationFactor = BigInt(10000000000000000000);
        const timestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            data.milton.test_openPosition(
                timestamp,
                asset,
                collateral,
                slippageValue,
                collateralizationFactor,
                direction
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
            libraries
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

        let collateralWad = USD_9063__63_18DEC;
        let openingFee = TC_OPENING_FEE_18DEC;

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad + params.totalAmount;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee;
        let expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            userTwo,
            userTwo,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            BigInt("9990000000000000000000000"),
            BigInt("9990000000000000000000000"),
            expectedLiquidityPoolTotalBalanceWad,
            1,
            BigInt("9940179461615154536391"),
            USD_20_18DEC,
            BigInt("0")
        );

        const actualPayFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonStorage.balances(params.asset)
            ).payFixedDerivatives
        );
        const actualRecFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonStorage.balances(params.asset)
            ).recFixedDerivatives
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
            libraries
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

        let collateralWad = USD_9063__63_18DEC;
        let openingFee = TC_OPENING_FEE_18DEC;

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let miltonBalanceBeforePayout = USD_14_000_6DEC;
        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayout,
                params.openTimestamp
            );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayout + params.totalAmount;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee;
        let expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        //then
        await assertExpectedValues(
            testData,
            params.asset,
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
                await testData.miltonStorage.balances(params.asset)
            ).payFixedDerivatives
        );

        const actualRecFixDerivativesBalanceWad = BigInt(
            await (
                await testData.miltonStorage.balances(params.asset)
            ).recFixedDerivatives
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
            libraries
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

        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;
        let liquidationDepositAmount = USD_20_18DEC;

        let incomeTax = BigInt("0");
        let incomeTaxWad = BigInt("0");

        let totalAmount = USD_10_000_18DEC;
        let collateral = USD_9063__63_18DEC;
        let openingFee = TC_OPENING_FEE_18DEC;

        let diffAfterClose =
            totalAmount - collateral - liquidationDepositAmount;

        let expectedOpenerUserUnderlyingTokenBalanceAfterPayOut =
            USER_SUPPLY_18_DECIMALS - diffAfterClose;
        let expectedCloserUserUnderlyingTokenBalanceAfterPayOut =
            USER_SUPPLY_18_DECIMALS - diffAfterClose;

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad + diffAfterClose;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee - incomeTax;

        await exetuceClosePositionTestCase(
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
            incomeTax,
            ZERO,
            null
        );
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("6808342096996681189");
        let incomeTaxWad = BigInt("6808342096996681189");
        let interestAmount = BigInt("68083420969966811892");
        let interestAmountWad = BigInt("68083420969966811892");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            libraries
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

        let incomeTax = BigInt("6808342");
        let incomeTaxWad = BigInt("6808342096996681189");
        let interestAmount = BigInt("68083421");
        let interestAmountWad = BigInt("68083420969966811892");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenUsdt.address,
            USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_365_18DEC,
            PERCENTAGE_365_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT open position because Liquidity Pool balance is to low", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        let closePositionTimestamp =
            params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                BigInt("10000000000000000"),
                params.openTimestamp
            );
        await openPositionFunc(params);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                BigInt("1600000000000000000"),
                params.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                BigInt("50000000000000000"),
                closePositionTimestamp
            );

        await data.iporConfiguration.setJoseph(userOne.address);
        await testData.miltonStorage
            .connect(userOne)
            .subtractLiquidity(params.asset, params.totalAmount);
        await data.iporConfiguration.setJoseph(data.joseph.address);

        //when
        await assertError(
            //when
            data.milton
                .connect(userTwo)
                .test_closePosition(1, closePositionTimestamp),
            //then
            "IPOR_14"
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Collateral, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost > Collateral, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_6DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenUsdt.address,
            USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_160_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("789767683251615021364");
        let incomeTaxWad = BigInt("789767683251615021364");
        let interestAmount = BigInt("7897676832516150213639");
        let interestAmountWad = BigInt("7897676832516150213639");
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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            libraries
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

        let incomeTax = BigInt("789767683");
        let incomeTaxWad = BigInt("789767683251615021364");
        let interestAmount = BigInt("7897676833");
        let interestAmountWad = BigInt("7897676832516150213639");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenUsdt.address,
            USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_120_18DEC,
            PERCENTAGE_5_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("854583100015023419750");
        let incomeTaxWad = BigInt("854583100015023419750");
        let interestAmount = BigInt("8545831000150234197501");
        let interestAmountWad = BigInt("8545831000150234197501");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = BigInt("9940179461");
        let interestAmountWad = BigInt("9940179461615154536391");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenUsdt.address,
            USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_160_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("776150999057621653403");
        let incomeTaxWad = BigInt("776150999057621653403");
        let interestAmount = BigInt("7761509990576216534025");
        let interestAmountWad = BigInt("7761509990576216534025");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            libraries
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

        let incomeTax = BigInt("776150999");
        let incomeTaxWad = BigInt("776150999057621653403");
        let interestAmount = BigInt("7761509990");
        let interestAmountWad = BigInt("7761509990576216534025");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenUsdt.address,
            USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            PERCENTAGE_5_18DEC,
            PERCENTAGE_120_18DEC,
            PERIOD_25_DAYS_IN_SECONDS,
            0,
            ZERO,
            ZERO,
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = SPECIFIC_INCOME_TAX_CASE_1;
        let incomeTaxWad = SPECIFIC_INCOME_TAX_CASE_1;
        let interestAmount = SPECIFIC_INTEREST_AMOUNT_CASE_1;
        let interestAmountWad = SPECIFIC_INTEREST_AMOUNT_CASE_1;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_5_18DEC,
                params.openTimestamp
            );
        await openPositionFunc(params);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_120_18DEC,
                params.openTimestamp
            );
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.warren
            .connect(userOne)
            .test_updateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            data.milton.connect(userThree).test_closePosition(1, endTimestamp),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("635082150807850422837");
        let incomeTaxWad = BigInt("635082150807850422837");
        let interestAmount = BigInt("6350821508078504228366");
        let interestAmountWad = BigInt("6350821508078504228366");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, before maturity", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_120_18DEC,
                params.openTimestamp
            );
        await openPositionFunc(params);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_5_18DEC,
                params.openTimestamp
            );
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.warren
            .connect(userOne)
            .test_updateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            data.milton.connect(userThree).test_closePosition(1, endTimestamp),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("854583100015023419750");
        let incomeTaxWad = BigInt("854583100015023419750");
        let interestAmount = BigInt("8545831000150234197501");
        let interestAmountWad = BigInt("8545831000150234197501");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price not changed, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("6808342096996679147");
        let incomeTaxWad = BigInt("6808342096996679147");
        let interestAmount = BigInt("68083420969966791467");
        let interestAmountWad = BigInt("68083420969966791467");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price changed 25%, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("6808342096996681189");
        let incomeTaxWad = BigInt("6808342096996681189");
        let interestAmount = BigInt("68083420969966811892");
        let interestAmountWad = BigInt("68083420969966811892");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User earned < Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("279142025976863929170");
        let incomeTaxWad = BigInt("279142025976863929170");
        let interestAmount = BigInt("2791420259768639291701");
        let interestAmountWad = BigInt("2791420259768639291701");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("789767683251615015781");
        let incomeTaxWad = BigInt("789767683251615015781");
        let interestAmount = BigInt("7897676832516150157811");
        let interestAmountWad = BigInt("7897676832516150157811");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("839332413717750853886");
        let incomeTaxWad = BigInt("839332413717750853886");
        let interestAmount = BigInt("8393324137177508538862");
        let interestAmountWad = BigInt("8393324137177508538862");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("650332837105122988701");
        let incomeTaxWad = BigInt("650332837105122988701");
        let interestAmount = BigInt("6503328371051229887005");
        let interestAmountWad = BigInt("6503328371051229887005");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_120_18DEC,
                params.openTimestamp
            );
        await openPositionFunc(params);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_5_18DEC,
                params.openTimestamp
            );
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.warren
            .connect(userOne)
            .test_updateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            data.milton.connect(userThree).test_closePosition(1, endTimestamp),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_5_18DEC,
                params.openTimestamp
            );
        await openPositionFunc(params);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_120_18DEC,
                params.openTimestamp
            );
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.warren
            .connect(userOne)
            .test_updateIndex(params.asset, PERCENTAGE_6_18DEC, endTimestamp);

        //when
        await assertError(
            //when
            data.milton.connect(userThree).test_closePosition(1, endTimestamp),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("839332413717750853886");
        let incomeTaxWad = BigInt("839332413717750853886");
        let interestAmount = BigInt("8393324137177508538862");
        let interestAmountWad = BigInt("8393324137177508538862");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("650332837105122988701");
        let incomeTaxWad = BigInt("650332837105122988701");
        let interestAmount = BigInt("6503328371051229887005");
        let interestAmountWad = BigInt("6503328371051229887005");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, because incorrect derivative Id", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParamsFirst.openTimestamp
            );
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParamsFirst.asset,
                USD_14_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await openPositionFunc(derivativeParamsFirst);

        await assertError(
            //when
            data.milton
                .connect(closerUser)
                .test_closePosition(
                    0,
                    openTimestamp + PERIOD_25_DAYS_IN_SECONDS
                ),
            //then
            "IPOR_22"
        );
    });

    it("should NOT close position, because derivative has incorrect status", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParamsFirst.openTimestamp
            );
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParamsFirst.asset,
                USD_14_000_18DEC + USD_14_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openPositionFunc(derivativeParams25days);

        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await data.milton
            .connect(closerUser)
            .test_closePosition(1, endTimestamp);

        await assertError(
            //when
            data.milton.connect(closerUser).test_closePosition(1, endTimestamp),
            //then
            "IPOR_23"
        );
    });

    it("should NOT close position, because derivative not exists", async () => {
        //given
        let closerUser = userTwo;
        let openTimestamp = Math.floor(Date.now() / 1000);

        await assertError(
            //when
            data.milton
                .connect(closerUser)
                .test_closePosition(
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
            libraries
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

        let direction = 0;
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParamsFirst.asset,
                USD_14_000_18DEC + USD_14_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParamsFirst.openTimestamp
            );
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openPositionFunc(derivativeParams25days);
        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(2);

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(1, endTimestamp);

        //then
        let actualDerivatives = await testData.miltonStorage.getPositions();
        let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);

        expect(
            expectedOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`
        ).to.be.eq(actualOpenedPositionsVol);

        let oneDerivative = actualDerivatives[0];

        expect(
            expectedDerivativeId,
            `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`
        ).to.be.eq(BigInt(oneDerivative.id));
    });

    it("should close only one position - close last position", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParamsFirst.asset,
                USD_14_000_18DEC + USD_14_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParamsFirst.openTimestamp
            );
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        await openPositionFunc(derivativeParams25days);
        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(1);

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(2, endTimestamp);

        //then
        let actualDerivatives = await testData.miltonStorage.getPositions();
        let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);

        expect(
            expectedOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`
        ).to.be.eq(actualOpenedPositionsVol);

        let oneDerivative = actualDerivatives[0];

        expect(
            expectedDerivativeId,
            `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`
        ).to.be.eq(BigInt(oneDerivative.id));
    });

    it("should close position with appropriate balance, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity, IPOR index calculated before close", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let incomeTax = BigInt("635082150807850422837");
        let interestAmount = BigInt("6350821508078504228366");
        let asset = testData.tokenDai.address;
        let collateralizationFactor = USD_10_18DEC;
        let direction = 0;
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_5_18DEC;
        let iporValueAfterOpenPosition = PERCENTAGE_50_18DEC;
        let periodOfTimeElapsedInSeconds = PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositions = 0;
        let expectedDerivativesTotalBalanceWad = ZERO;
        let expectedLiquidationDepositTotalBalanceWad = ZERO;
        let expectedTreasuryTotalBalanceWad = incomeTax;
        let expectedSoap = ZERO;
        let openTimestamp = null;

        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;

        let closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        let openerUserLost =
            TC_OPENING_FEE_18DEC +
            TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
            interestAmount +
            incomeTax;

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
            interestAmount +
            incomeTax;

        let expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_18_DECIMALS + openerUserEarned - openerUserLost;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_18_DECIMALS + closerUserEarned - closerUserLost;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad -
            interestAmount +
            TC_OPENING_FEE_18DEC;

        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }
        const params = {
            asset: asset,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: collateralizationFactor,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUser,
        };

        if (miltonBalanceBeforePayoutWad != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await data.joseph
                .connect(liquidityProvider)
                .test_provideLiquidity(
                    params.asset,
                    miltonBalanceBeforePayoutWad,
                    params.openTimestamp
                );
        }

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                iporValueBeforeOpenPosition,
                params.openTimestamp
            );
        await openPositionFunc(params);
        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                iporValueAfterOpenPosition,
                params.openTimestamp
            );

        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                iporValueAfterOpenPosition,
                endTimestamp - 1
            );

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(1, endTimestamp);

        //then
        await assertExpectedValues(
            testData,
            params.asset,
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
        await assertSoap(soapParams);
    });

    it("should open many positions and arrays with ids have correct state, one user", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLength = 3;
        let expectedDerivativeIdsLength = 3;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                BigInt(3) * USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );

        //when
        await openPositionFunc(derivativeParams);
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);

        //then
        let actualUserDerivativeIds =
            await testData.miltonStorage.getUserDerivativeIds(
                openerUser.address
            );
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        expect(
            expectedUserDerivativeIdsLength,
            `Incorrect user derivative ids length actual: ${actualUserDerivativeIds.length}, expected: ${expectedUserDerivativeIdsLength}`
        ).to.be.eq(actualUserDerivativeIds.length);
        expect(
            expectedDerivativeIdsLength,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        ).to.be.eq(actualDerivativeIds.length);

        await assertMiltonDerivativeItem(testData, 1, 0, 0);
        await assertMiltonDerivativeItem(testData, 2, 1, 1);
        await assertMiltonDerivativeItem(testData, 3, 2, 2);
    });

    it("should open many positions and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 1;
        let expectedDerivativeIdsLength = 3;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                BigInt(3) * USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );

        //when
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(
                userThree.address
            );
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
        expect(
            expectedDerivativeIdsLength,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        ).to.be.eq(actualDerivativeIds.length);

        await assertMiltonDerivativeItem(testData, 1, 0, 0);
        await assertMiltonDerivativeItem(testData, 2, 1, 0);
        await assertMiltonDerivativeItem(testData, 3, 2, 1);
    });

    it("should open many positions and close one position and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 2;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                BigInt(3) * USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton
            .connect(userThree)
            .test_closePosition(
                2,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(
                userThree.address
            );
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
        expect(
            expectedDerivativeIdsLength,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        ).to.be.eq(actualDerivativeIds.length);

        await assertMiltonDerivativeItem(testData, 1, 0, 0);
        await assertMiltonDerivativeItem(testData, 3, 1, 1);
    });

    it("should open many positions and close two positions and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 1;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 1;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                BigInt(3) * USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton
            .connect(userThree)
            .test_closePosition(
                2,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );
        await data.milton
            .connect(userTwo)
            .test_closePosition(
                3,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(
                userThree.address
            );
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
        expect(
            expectedDerivativeIdsLength,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        ).to.be.eq(actualDerivativeIds.length);

        await assertMiltonDerivativeItem(testData, 1, 0, 0);
    });

    it("should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                BigInt(2) * USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton
            .connect(userThree)
            .test_closePosition(
                1,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );
        await data.milton
            .connect(userThree)
            .test_closePosition(
                2,
                derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
        expect(
            expectedDerivativeIdsLength,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        ).to.be.eq(actualDerivativeIds.length);
    });

    it("should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1 with minus 3", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                BigInt(2) * USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS - 3;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton
            .connect(userThree)
            .test_closePosition(
                1,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );
        await data.milton
            .connect(userThree)
            .test_closePosition(
                2,
                derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
        expect(
            expectedDerivativeIdsLength,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        ).to.be.eq(actualDerivativeIds.length);
    });

    it("should open two positions and close one position - Arithmetic overflow - last byte difference - case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        let direction = 0;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                BigInt(2) * USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        derivativeParams.from = userThree;
        derivativeParams.direction = 0;
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        derivativeParams.direction = 0;
        await openPositionFunc(derivativeParams);

        await data.milton
            .connect(userThree)
            .test_closePosition(
                1,
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS
            );

        //when
        await data.milton
            .connect(userThree)
            .test_closePosition(
                2,
                derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS
            );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userTwo.address);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        expect(
            expectedUserDerivativeIdsLengthFirst,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        ).to.be.eq(actualUserDerivativeIdsFirst.length);
        expect(
            expectedUserDerivativeIdsLengthSecond,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        ).to.be.eq(actualUserDerivativeIdsSecond.length);
        expect(
            expectedDerivativeIdsLength,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        ).to.be.eq(actualDerivativeIds.length);
    });

    it("should calculate income tax, 5%, not owner, Milton loses, user earns, |I| < D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
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
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_5_18DEC
        );

        let incomeTax = BigInt("419666206858875426943");
        let incomeTaxWad = BigInt("419666206858875426943");
        let interestAmount = BigInt("8393324137177508538862");
        let interestAmountWad = BigInt("8393324137177508538862");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 5%, Milton loses, user earns, |I| > D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin.address
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_5_18DEC
        );

        let incomeTax = BigInt("497008973080757726820");
        let incomeTaxWad = BigInt("497008973080757726820");

        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 5%, Milton earns, user loses, |I| < D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
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

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_5_18DEC
        );

        let incomeTax = BigInt("394883841625807510682");
        let incomeTaxWad = BigInt("394883841625807510682");
        let interestAmount = BigInt("7897676832516150213639");
        let interestAmountWad = BigInt("7897676832516150213639");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 5%, Milton earns, user loses, |I| > D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
    });

    it("should calculate income tax, 5%, Milton earns, user loses, |I| > D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
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

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_5_18DEC
        );

        let incomeTax = BigInt("497008973080757726820");
        let incomeTaxWad = BigInt("497008973080757726820");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 100%, Milton loses, user earns, |I| < D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
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
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_100_18DEC
        );

        let incomeTax = BigInt("8393324137177508538862");
        let incomeTaxWad = BigInt("8393324137177508538862");
        let interestAmount = BigInt("8393324137177508538862");
        let interestAmountWad = BigInt("8393324137177508538862");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 100%, Milton loses, user earns, |I| > D", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
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
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_100_18DEC
        );

        let incomeTax = BigInt("9940179461615154536391");
        let incomeTaxWad = BigInt("9940179461615154536391");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 100%, Milton earns, user loses, |I| < D, to low liquidity pool", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
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

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_100_18DEC
        );
        let incomeTax = BigInt("7897676832516150213639");
        let incomeTaxWad = BigInt("7897676832516150213639");
        let interestAmount = BigInt("7897676832516150213639");
        let interestAmountWad = BigInt("7897676832516150213639");

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 100%, Milton earns, user loses, |I| > D, to low liquidity pool", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
    });

    it("should calculate income tax, 100%, Milton earns, user loses, |I| > D, to low liquidity pool", async () => {
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
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
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_100_18DEC
        );

        let incomeTax = BigInt("9940179461615154536391");
        let incomeTaxWad = BigInt("9940179461615154536391");
        let interestAmount = TC_COLLATERAL_18DEC;
        let interestAmountWad = TC_COLLATERAL_18DEC;

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
            incomeTaxWad,
            ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            PERCENTAGE_10_18DEC
        );
    });

    it("should open pay fixed position, DAI, custom Opening Fee for Treasury 50%", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
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

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        await testData.iporAssetConfigurationDai.setOpeningFeeForTreasuryPercentage(
            BigInt("50000000000000000")
        );

        let expectedOpeningFeeTotalBalanceWad = TC_OPENING_FEE_18DEC;
        let expectedTreasuryTotalBalanceWad = BigInt("1491026919242273180");

        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + BigInt("28329511465603190429");
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        //when
        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

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

        await testData.iporAssetConfigurationDai.setOpeningFeeForTreasuryPercentage(
            ZERO
        );
    });

    it("should open pay fixed position, DAI, custom Opening Fee for Treasury 25%", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
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

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        await testData.iporAssetConfigurationDai.setOpeningFeeForTreasuryPercentage(
            BigInt("25000000000000000")
        );

        let expectedOpeningFeeTotalBalanceWad = TC_OPENING_FEE_18DEC;
        let expectedTreasuryTotalBalanceWad = BigInt("745513459621136590");

        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + BigInt("29075024925224327019");
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        //when
        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

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

        await testData.iporAssetConfigurationDai.setOpeningFeeForTreasuryPercentage(
            ZERO
        );
    });

    it("should NOT transfer Publication Fee to Charlie Treasury - caller not publication fee transferer", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );

        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        //when
        await assertError(
            //when
            data.milton.transferPublicationFee(
                testData.tokenDai.address,
                BigInt("100")
            ),
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
            libraries
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

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );

        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
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
            data.milton.transferPublicationFee(
                testData.tokenDai.address,
                BigInt("100")
            ),
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
            libraries
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

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );

        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        await data.iporConfiguration.setMiltonPublicationFeeTransferer(
            admin.address
        );
        await testData.iporAssetConfigurationDai.setCharlieTreasurer(
            userThree.address
        );

        const transferedAmount = BigInt("100");

        //when
        await data.milton.transferPublicationFee(
            testData.tokenDai.address,
            transferedAmount
        );

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

        let expectedErc20BalanceCharlieTreasurer =
            USER_SUPPLY_18_DECIMALS + transferedAmount;
        let actualErc20BalanceCharlieTreasurer = BigInt(
            await testData.tokenDai.balanceOf(userThree.address)
        );

        let expectedErc20BalanceMilton =
            USD_14_000_18DEC + USD_10_000_18DEC - transferedAmount;
        let actualErc20BalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(data.milton.address)
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
            libraries
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
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await assertError(
            //when
            data.milton
                .connect(userTwo)
                .test_openPosition(
                    params.openTimestamp,
                    params.asset,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor,
                    params.direction
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
            libraries
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
            collateralizationFactor: BigInt("50000000000000000001"),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await assertError(
            //when
            data.milton
                .connect(userTwo)
                .test_openPosition(
                    params.openTimestamp,
                    params.asset,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor,
                    params.direction
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
            libraries
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
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                USD_14_000_18DEC,
                params.openTimestamp
            );

        //when
        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        //then
        let actualDerivativeItem =
            await testData.miltonStorage.getDerivativeItem(1);
        let actualNotionalAmount = BigInt(
            actualDerivativeItem.item.notionalAmount
        );
        let expectedNotionalAmount = BigInt("150115102721401640058243");

        expect(
            expectedNotionalAmount,
            `Incorrect notional amount for ${params.asset}, actual:  ${actualNotionalAmount},
            expected: ${expectedNotionalAmount}`
        ).to.be.eq(actualNotionalAmount);
    });

    it("should open pay fixed position - liquidity pool utilisation not exceeded, custom utilisation", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
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

        let closerUserEarned = ZERO;
        let openerUserLost =
            TC_OPENING_FEE_18DEC +
            TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC +
            TC_COLLATERAL_18DEC;

        let closerUserLost = openerUserLost;
        let openerUserEarned = closerUserEarned;

        let expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_18_DECIMALS + openerUserEarned - openerUserLost;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose =
            USER_SUPPLY_18_DECIMALS + closerUserEarned - closerUserLost;

        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad +
            TC_OPENING_FEE_18DEC +
            TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            TC_COLLATERAL_18DEC +
            TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + TC_OPENING_FEE_18DEC;

        let oldLiquidityPoolMaxUtilizationPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();

        let liquidityPoolMaxUtilizationEdge = BigInt(718503678605107622);

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            liquidityPoolMaxUtilizationEdge
        );

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            userTwo,
            userTwo,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterClose,
            expectedCloserUserUnderlyingTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalanceWad,
            1,
            TC_COLLATERAL_18DEC,
            USD_20_18DEC,
            ZERO
        );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            oldLiquidityPoolMaxUtilizationPercentage
        );
    });

    it("should NOT open pay fixed position - when new position opened then liquidity pool utilisation exceeded, custom utilisation", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
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

        let miltonBalanceBeforePayoutWad = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        let oldLiquidityPoolMaxUtilizationPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();

        let liquidityPoolMaxUtilizationEdge = BigInt(608038055741904007);

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            liquidityPoolMaxUtilizationEdge
        );

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        //when
        await assertError(
            //when
            data.milton
                .connect(userTwo)
                .test_openPosition(
                    params.openTimestamp,
                    params.asset,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor,
                    params.direction
                ),
            //then
            "IPOR_35"
        );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            oldLiquidityPoolMaxUtilizationPercentage
        );
    });

    it("should NOT open pay fixed position - liquidity pool utilisation already exceeded, custom utilisation", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
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

        let oldLiquidityPoolMaxUtilizationPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        let liquiditiPoolMaxUtilizationEdge = BigInt(758503678605107622);
        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            liquiditiPoolMaxUtilizationEdge
        );

        //First open position not exceeded liquidity utilization
        await data.milton
            .connect(userTwo)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );

        //when
        //Second open position exceeded liquidity utilization
        await assertError(
            //when
            data.milton
                .connect(userTwo)
                .test_openPosition(
                    params.openTimestamp,
                    params.asset,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor,
                    params.direction
                ),
            //then
            "IPOR_35"
        );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            oldLiquidityPoolMaxUtilizationPercentage
        );
    });

    //TODO: clarify when spread equasion will be clarified
    // it("should NOT open pay fixed position - liquidity pool utilisation exceeded, liquidity pool and opening fee are ZERO", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
    //         admin.address
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
    //         admin.address
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
    //         admin.address
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
    //         admin.address
    //     );
    //     await prepareApproveForUsers(
    //         [userOne, userTwo, userThree, liquidityProvider],
    //         "DAI",
    //         data,
    //         testData
    //     );
    //     await setupTokenDaiInitialValuesForUsers(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         testData
    //     );
    //     const params = getPayFixedDerivativeParamsDAICase1(
    //         userTwo,
    //         testData
    //     );

    //     let oldLiquidityPoolMaxUtilizationPercentage =
    //         await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();
    //     let oldOpeningFeePercentage =
    //         await testData.iporAssetConfigurationDai.getOpeningFeePercentage();

    //     await data.warren.connect(userOne).test_updateIndex(
    //         params.asset,
    //         PERCENTAGE_3_18DEC,
    //         params.openTimestamp
    //     );

    //     await testData.iporAssetConfigurationDai.setOpeningFeePercentage(ZERO);
    //     //very high value
    //     await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
    //         BigInt(99999999999999999999999999999999999999999)
    //     );

    //     await assertError(
    //         //when
    //         data.milton.connect(userTwo).test_openPosition(
    //             params.openTimestamp,
    //             params.asset,
    //             params.totalAmount,
    //             params.slippageValue,
    //             params.collateralizationFactor,
    //             params.direction
    //         ),
    //         //then
    //         "IPOR_35"
    //     );

    //     await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
    //         oldLiquidityPoolMaxUtilizationPercentage
    //     );
    //     await testData.iporAssetConfigurationDai.setOpeningFeePercentage(
    //         oldOpeningFeePercentage
    //     );
    // });

    it("should open pay fixed position - when open timestamp is long time ago", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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
        let incomeTax = ZERO;
        let incomeTaxWad = ZERO;
        let interestAmount = ZERO;
        let interestAmountWad = ZERO;

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
            incomeTaxWad,
            ZERO,
            veryLongTimeAgoTimestamp,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT open pay fixed position - asset address not supported", async () => {
        //given

        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );

        //when
        await assertError(
            //when
            data.milton
                .connect(userTwo)
                .test_openPosition(
                    params.openTimestamp,
                    liquidityProvider.address,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor,
                    params.direction
                ),
            //then
            "IPOR_39"
        );
    });

    it("should calculate Position Value - simple case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
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

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );
        let miltonBalanceBeforePayoutWad = USD_14_000_18DEC;
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp
            );
        await openPositionFunc(params);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let expectedPositionValue = BigInt("-38126715743181445978");

        //when
        let actualPositionValue = BigInt(
            await data.milton.test_calculatePositionValue(
                params.openTimestamp + PERIOD_14_DAYS_IN_SECONDS,
                derivativeItem.item
            )
        );

        //then
        expect(
            expectedPositionValue,
            `Incorrect position value, actual: ${actualPositionValue}, expected: ${expectedPositionValue}`
        ).to.be.eq(actualPositionValue);
    });

    const calculateSoap = async (params) => {
        return await data.milton
            .connect(params.from)
            .test_calculateSoap(params.asset, params.calculateTimestamp);
    };

    const openPositionFunc = async (params) => {
        await data.milton
            .connect(params.from)
            .test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction
            );
    };

    const countOpenPositions = (derivatives) => {
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
        derivativeId,
        expectedIdsIndex,
        expectedUserDerivativeIdsIndex
    ) => {
        let actualDerivativeItem =
            await testData.miltonStorage.getDerivativeItem(derivativeId);
        expect(
            BigInt(expectedIdsIndex),
            `Incorrect idsIndex for derivative id ${actualDerivativeItem.item.id} actual: ${actualDerivativeItem.idsIndex}, expected: ${expectedIdsIndex}`
        ).to.be.eq(BigInt(actualDerivativeItem.idsIndex));
        expect(
            BigInt(expectedUserDerivativeIdsIndex),
            `Incorrect userDerivativeIdsIndex for derivative id ${actualDerivativeItem.item.id} actual: ${actualDerivativeItem.userDerivativeIdsIndex}, expected: ${expectedUserDerivativeIdsIndex}`
        ).to.be.eq(BigInt(actualDerivativeItem.userDerivativeIdsIndex));
    };

    const testCaseWhenMiltonEarnAndUserLost = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenPosition,
        iporValueAfterOpenPosition,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        incomeTax,
        incomeTaxWad,
        interestAmount,
        interestAmountWad
    ) {
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
            interestAmountWad -
            incomeTaxWad;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC +
                interestAmount;

            if (openerUser.address === closerUser.address) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_18_DECIMALS + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_18_DECIMALS + closerUserEarned - closerUserLost;
            expectedMiltonUnderlyingTokenBalance =
                TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                interestAmount;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
            openerUserLost =
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC +
                interestAmount;

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
                interestAmount;
        }

        await exetuceClosePositionTestCase(
            testData,
            asset,
            collateralizationFactor,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenPosition,
            iporValueAfterOpenPosition,
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
            openTimestamp
        );
    };

    const testCaseWhenMiltonLostAndUserEarn = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenPosition,
        iporValueAfterOpenPosition,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedLiquidationDepositTotalBalanceWad,
        expectedTreasuryTotalBalanceWad,
        expectedSoap,
        openTimestamp,
        incomeTax,
        incomeTaxWad,
        interestAmount,
        interestAmountWad
    ) {
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
            interestAmountWad +
            TC_OPENING_FEE_18DEC;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                TC_OPENING_FEE_18DEC +
                TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
                interestAmount +
                incomeTax;

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
                interestAmount +
                incomeTax;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_18_DECIMALS + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_18_DECIMALS + closerUserEarned - closerUserLost;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            miltonBalanceBeforePayout = TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
            closerUserEarned = TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
            openerUserLost =
                TC_OPENING_FEE_6DEC +
                TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC -
                interestAmount +
                incomeTax;

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
                interestAmount +
                incomeTax;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + openerUserEarned - openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                USER_SUPPLY_6_DECIMALS + closerUserEarned - closerUserLost;
        }

        await exetuceClosePositionTestCase(
            testData,
            asset,
            collateralizationFactor,
            direction,
            openerUser,
            closerUser,
            iporValueBeforeOpenPosition,
            iporValueAfterOpenPosition,
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
            openTimestamp
        );
    };

    const exetuceClosePositionTestCase = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUser,
        closerUser,
        iporValueBeforeOpenPosition,
        iporValueAfterOpenPosition,
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
        openTimestamp
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
            await data.joseph
                .connect(liquidityProvider)
                .test_provideLiquidity(
                    params.asset,
                    providedLiquidityAmount,
                    params.openTimestamp
                );
        }

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                iporValueBeforeOpenPosition,
                params.openTimestamp
            );
        await openPositionFunc(params);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                params.asset,
                iporValueAfterOpenPosition,
                params.openTimestamp
            );

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(1, endTimestamp);

        //then
        await assertExpectedValues(
            testData,
            params.asset,
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
        await assertSoap(soapParams);
    };

    const assertExpectedValues = async function (
        testData,
        asset,
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
        let actualDerivatives = await testData.miltonStorage.getPositions();
        let actualOpenPositionsVol = countOpenPositions(actualDerivatives);

        expect(
            expectedOpenedPositions,
            `Incorrect number of opened derivatives, actual:  ${actualOpenPositionsVol}, expected: ${expectedOpenedPositions}`
        ).to.be.eq(actualOpenPositionsVol);

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
                await testData.tokenDai.balanceOf(data.milton.address)
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
                await testData.tokenUsdt.balanceOf(data.milton.address)
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

    const assertSoap = async (params) => {
        let actualSoapStruct = await calculateSoap(params);
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

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            actualOpenerUserUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(openerUser.address)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(closerUser.address)
            );
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            actualOpenerUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(openerUser.address)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(closerUser.address)
            );
        }

        let balance = await testData.miltonStorage.balances(asset);

        let actualMiltonUnderlyingTokenBalance = null;
        if (testData.tokenDai && asset === testData.tokenDai.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(data.milton.address)
            );
        }
        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(data.milton.address)
            );
        }
        if (testData.tokenUsdc && asset === testData.tokenUsdc.address) {
            actualMiltonUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdc.balanceOf(data.milton.address)
            );
        }

        const actualPayFixedDerivativesBalance = BigInt(
            balance.payFixedDerivatives
        );
        const actualRecFixedDerivativesBalance = BigInt(
            balance.recFixedDerivatives
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

//TODO: !!!! add test when before open position liquidity pool is empty and opening fee is zero - then spread cannot be calculated in correct way!!!

//TODO: !!!! add test when closing derivative, Milton lost, Trader earn, but milton don't have enough balance to withdraw during closing position

//TODO: check initial IBT

//TODO: test when transfer ownership and Milton still works properly

//TODO: add test: open long, change index, open short, change index, close long and short and check if soap = 0

//TODO: add simple test where iporassetcopnfiguration or iporconfiguration is changing and milton see this.

//TODO: test when ipor not ready yet

//TODO: create test when ipor index not yet created for specific asset

//TODO: add test where total amount higher than openingfeeamount

//TODO: add test which checks emited events!!!
//TODO: add test when warren address will change and check if milton see this
//TODO: add test when user try to send eth on milton
//TODO: add test where milton storage is changing - how balance behave
//TODO: add tests for pausable methods
