const keccak256 = require("keccak256");
const testUtils = require("./TestUtils.js");
const { ZERO } = require("./TestUtils");

contract("Milton", (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let data = null;
    let testData = null;

    before(async () => {
        data = await testUtils.prepareData();
    });

    it("should NOT open position because deposit amount too low", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let asset = testData.tokenDai.address;
        let collateral = 0;
        let slippageValue = 3;
        let direction = 0;
        let collateralizationFactor = testUtils.USD_10_18DEC;
        let timestamp = Math.floor(Date.now() / 1000);
        await testUtils.assertError(
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let asset = testData.tokenDai.address;
        let collateral = BigInt("30000000000000000001");
        let slippageValue = 0;
        let direction = 0;
        let collateralizationFactor = testUtils.USD_10_18DEC;
        let timestamp = Math.floor(Date.now() / 1000);
        await testUtils.assertError(
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let asset = testData.tokenDai.address;
        let collateral = BigInt("30000000000000000001");
        let slippageValue = web3.utils.toBN(1e20);
        let theOne = web3.utils.toBN(1);
        slippageValue = slippageValue.add(theOne);
        let direction = 0;
        let collateralizationFactor = testUtils.USD_10_18DEC;
        let timestamp = Math.floor(Date.now() / 1000);

        await testUtils.assertError(
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await testUtils.setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let asset = testData.tokenUsdt.address;
        let collateral = BigInt("30000001");
        let slippageValue = web3.utils.toBN(1e8);
        let theOne = web3.utils.toBN(1);
        slippageValue = slippageValue.add(theOne);
        let direction = 0;
        let collateralizationFactor = testUtils.USD_10_6DEC;
        let timestamp = Math.floor(Date.now() / 1000);

        await testUtils.assertError(
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let asset = testData.tokenDai.address;
        let collateral = BigInt("1000000000000000000000001");
        let slippageValue = 3;
        let direction = 0;
        let collateralizationFactor = BigInt(10000000000000000000);
        let timestamp = Math.floor(Date.now() / 1000);

        await testUtils.assertError(
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        let collateralWad = testUtils.USD_9063__63_18DEC;
        let openingFee = testUtils.TC_OPENING_FEE_18DEC;

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        let miltonBalanceBeforePayoutWad = testUtils.USD_14_000_18DEC;
        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayoutWad,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad + params.totalAmount;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee;
        let expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
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
            testUtils.USD_20_18DEC,
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

        assert(
            expectedDerivativesTotalBalanceWad ===
                actualDerivativesTotalBalanceWad,
            `Incorrect derivatives total balance for ${params.asset} actual ${actualDerivativesTotalBalanceWad}, expected ${expectedDerivativesTotalBalanceWad}Wad`
        );
    });

    it("should open pay fixed position - simple case USDT - 6 decimals", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await testUtils.setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsUSDTCase1(
            userTwo,
            testData
        );

        let collateralWad = testUtils.USD_9063__63_18DEC;
        let openingFee = testUtils.TC_OPENING_FEE_18DEC;

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        let miltonBalanceBeforePayout = testUtils.USD_14_000_6DEC;
        let miltonBalanceBeforePayoutWad = testUtils.USD_14_000_18DEC;

        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayout,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayout + params.totalAmount;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee;
        let expectedDerivativesTotalBalanceWad = collateralWad;

        //when
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
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
            testUtils.TC_COLLATERAL_18DEC,
            testUtils.USD_20_18DEC,
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

        assert(
            expectedDerivativesTotalBalanceWad ===
                actualDerivativesTotalBalanceWad,
            `Incorrect derivatives total balance for ${params.asset} actual ${actualDerivativesTotalBalanceWad}, expected ${expectedDerivativesTotalBalanceWad}Wad`
        );
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let miltonBalanceBeforePayoutWad = testUtils.USD_14_000_18DEC;
        let liquidationDepositAmount = testUtils.USD_20_18DEC;

        let incomeTax = BigInt("0");
        let incomeTaxWad = BigInt("0");

        let totalAmount = testUtils.USD_10_000_18DEC;
        let collateral = testUtils.USD_9063__63_18DEC;
        let openingFee = testUtils.TC_OPENING_FEE_18DEC;

        let diffAfterClose =
            totalAmount - collateral - liquidationDepositAmount;

        let expectedOpenerUserUnderlyingTokenBalanceAfterPayOut =
            testUtils.USER_SUPPLY_18_DECIMALS - diffAfterClose;
        let expectedCloserUserUnderlyingTokenBalanceAfterPayOut =
            testUtils.USER_SUPPLY_18_DECIMALS - diffAfterClose;

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad + diffAfterClose;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + openingFee - incomeTax;

        await exetuceClosePositionTestCase(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_3_18DEC,
            testUtils.PERCENTAGE_3_18DEC,
            0,
            miltonBalanceBeforePayoutWad,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
            expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalanceWad,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTax,
            testUtils.ZERO,
            null
        );
    });

    it("should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, DAI 18 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_365_18DEC,
            testUtils.PERCENTAGE_365_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity, USDT 6 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await testUtils.setupTokenUsdtInitialValuesForUsers(
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
            testUtils.USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_365_18DEC,
            testUtils.PERCENTAGE_365_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT open position because Liquidity Pool balance is to low", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: BigInt("10000000000000000000000"), //10 000 USD
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        let closePositionTimestamp =
            params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        await data.warren.test_updateIndex(
            params.asset,
            BigInt("10000000000000000"),
            params.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(params);
        await data.warren.test_updateIndex(
            params.asset,
            BigInt("1600000000000000000"),
            params.openTimestamp,
            { from: userOne }
        );
        await data.warren.test_updateIndex(
            params.asset,
            BigInt("50000000000000000"),
            closePositionTimestamp,
            { from: userOne }
        );

        await data.iporConfiguration.setJoseph(userOne);
        await testData.miltonStorage.subtractLiquidity(
            params.asset,
            params.totalAmount,
            { from: userOne }
        );
        await data.iporConfiguration.setJoseph(data.joseph.address);

        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, closePositionTimestamp, {
                from: userTwo,
            }),
            //then
            "IPOR_14"
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Collateral, before maturity, DAI 18 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost > Collateral, before maturity, USDT 6 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await testUtils.setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_6DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenUsdt.address,
            testUtils.USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton earned, User lost < Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await testUtils.setupTokenUsdtInitialValuesForUsers(
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
            testUtils.USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned > Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await testUtils.setupTokenUsdtInitialValuesForUsers(
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
            testUtils.USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, DAI 18 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, USDT, owner, pay fixed, Milton lost, User earned < Deposit, before maturity, USDT 6 decimals", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await testUtils.setupTokenUsdtInitialValuesForUsers(
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
            testUtils.USD_10_6DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = testUtils.SPECIFIC_INCOME_TAX_CASE_1;
        let incomeTaxWad = testUtils.SPECIFIC_INCOME_TAX_CASE_1;
        let interestAmount = testUtils.SPECIFIC_INTEREST_AMOUNT_CASE_1;
        let interestAmountWad = testUtils.SPECIFIC_INTEREST_AMOUNT_CASE_1;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_50_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_5_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(params);
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_120_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        let endTimestamp =
            params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_6_18DEC,
            endTimestamp,
            { from: userOne }
        );

        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {
                from: userThree,
            }),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_50_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, before maturity", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_120_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(params);
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_5_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        let endTimestamp =
            params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_6_18DEC,
            endTimestamp,
            { from: userOne }
        );

        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {
                from: userThree,
            }),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price not changed, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_3_18DEC,
            testUtils.PERCENTAGE_3_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price changed 25%, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_365_18DEC,
            testUtils.PERCENTAGE_365_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User earned < Deposit, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_50_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_120_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(params);
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_5_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        let endTimestamp =
            params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_6_18DEC,
            endTimestamp,
            { from: userOne }
        );

        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {
                from: userThree,
            }),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, before maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_5_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(params);
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_120_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        let endTimestamp =
            params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_6_18DEC,
            endTimestamp,
            { from: userOne }
        );

        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {
                from: userThree,
            }),
            //then
            "IPOR_16"
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton lost, User earned < Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, not owner, receive fixed, Milton earned, User lost < Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_50_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should close position, DAI, owner, pay fixed, Milton earned, User lost > Deposit, after maturity", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("994017946161515453639");
        let incomeTaxWad = BigInt("994017946161515453639");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT close position, because incorrect derivative Id", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress,
        };
        await data.warren.test_updateIndex(
            derivativeParamsFirst.asset,
            iporValueBeforeOpenPosition,
            derivativeParamsFirst.openTimestamp,
            { from: userOne }
        );
        await data.joseph.test_provideLiquidity(
            derivativeParamsFirst.asset,
            testUtils.USD_14_000_18DEC,
            derivativeParamsFirst.openTimestamp,
            { from: liquidityProvider }
        );
        await openPositionFunc(derivativeParamsFirst);

        await testUtils.assertError(
            //when
            data.milton.test_closePosition(
                0,
                openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
                { from: closerUserAddress }
            ),
            //then
            "IPOR_22"
        );
    });

    it("should NOT close position, because derivative has incorrect status", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress,
        };
        await data.warren.test_updateIndex(
            derivativeParamsFirst.asset,
            iporValueBeforeOpenPosition,
            derivativeParamsFirst.openTimestamp,
            { from: userOne }
        );
        await data.joseph.test_provideLiquidity(
            derivativeParamsFirst.asset,
            testUtils.USD_14_000_18DEC + testUtils.USD_14_000_18DEC,
            derivativeParamsFirst.openTimestamp,
            { from: liquidityProvider }
        );
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress,
        };
        await openPositionFunc(derivativeParams25days);

        let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS;

        await data.milton.test_closePosition(1, endTimestamp, {
            from: closerUserAddress,
        });

        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {
                from: closerUserAddress,
            }),
            //then
            "IPOR_23"
        );
    });

    it("should NOT close position, because derivative not exists", async () => {
        //given
        let closerUserAddress = userTwo;
        let openTimestamp = Math.floor(Date.now() / 1000);

        await testUtils.assertError(
            //when
            data.milton.test_closePosition(
                0,
                openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
                { from: closerUserAddress }
            ),
            //then
            "IPOR_22"
        );
    });

    it("should close only one position - close first position", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress,
        };
        await data.joseph.test_provideLiquidity(
            derivativeParamsFirst.asset,
            testUtils.USD_14_000_18DEC + testUtils.USD_14_000_18DEC,
            derivativeParamsFirst.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            derivativeParamsFirst.asset,
            iporValueBeforeOpenPosition,
            derivativeParamsFirst.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress,
        };
        await openPositionFunc(derivativeParams25days);
        let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(2);

        //when
        await data.milton.test_closePosition(1, endTimestamp, {
            from: closerUserAddress,
        });

        //then
        let actualDerivatives = await testData.miltonStorage.getPositions();
        let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);

        assert(
            expectedOpenedPositionsVol === actualOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`
        );

        let oneDerivative = actualDerivatives[0];

        assert(
            expectedDerivativeId === BigInt(oneDerivative.id),
            `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`
        );
    });

    it("should close only one position - close last position", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress,
        };
        await data.joseph.test_provideLiquidity(
            derivativeParamsFirst.asset,
            testUtils.USD_14_000_18DEC + testUtils.USD_14_000_18DEC,
            derivativeParamsFirst.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            derivativeParamsFirst.asset,
            iporValueBeforeOpenPosition,
            derivativeParamsFirst.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress,
        };
        await openPositionFunc(derivativeParams25days);
        let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(1);

        //when
        await data.milton.test_closePosition(2, endTimestamp, {
            from: closerUserAddress,
        });

        //then
        let actualDerivatives = await testData.miltonStorage.getPositions();
        let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);

        assert(
            expectedOpenedPositionsVol === actualOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`
        );

        let oneDerivative = actualDerivatives[0];

        assert(
            expectedDerivativeId === BigInt(oneDerivative.id),
            `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`
        );
    });

    it("should close position with appropriate balance, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity, IPOR index calculated before close", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let incomeTax = BigInt("635082150807850422837");
        let interestAmount = BigInt("6350821508078504228366");
        let asset = testData.tokenDai.address;
        let collateralizationFactor = testUtils.USD_10_18DEC;
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_5_18DEC;
        let iporValueAfterOpenPosition = testUtils.PERCENTAGE_50_18DEC;
        let periodOfTimeElapsedInSeconds = testUtils.PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositions = 0;
        let expectedDerivativesTotalBalanceWad = testUtils.ZERO;
        let expectedLiquidationDepositTotalBalanceWad = testUtils.ZERO;
        let expectedTreasuryTotalBalanceWad = incomeTax;
        let expectedSoap = testUtils.ZERO;
        let openTimestamp = null;

        let miltonBalanceBeforePayoutWad =
            testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC;

        let closerUserEarned = testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        let openerUserLost =
            testUtils.TC_OPENING_FEE_18DEC +
            testUtils.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
            interestAmount +
            incomeTax;

        let closerUserLost = null;
        let openerUserEarned = null;

        if (openerUserAddress === closerUserAddress) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad +
            testUtils.TC_OPENING_FEE_18DEC +
            testUtils.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
            interestAmount +
            incomeTax;

        let expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            testUtils.USER_SUPPLY_18_DECIMALS +
            openerUserEarned -
            openerUserLost;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose =
            testUtils.USER_SUPPLY_18_DECIMALS +
            closerUserEarned -
            closerUserLost;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad -
            interestAmount +
            testUtils.TC_OPENING_FEE_18DEC;

        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }
        const params = {
            asset: asset,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: collateralizationFactor,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUserAddress,
        };

        if (miltonBalanceBeforePayoutWad != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await data.joseph.test_provideLiquidity(
                params.asset,
                miltonBalanceBeforePayoutWad,
                params.openTimestamp,
                { from: liquidityProvider }
            );
        }

        await data.warren.test_updateIndex(
            params.asset,
            iporValueBeforeOpenPosition,
            params.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(params);
        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;
        await data.warren.test_updateIndex(
            params.asset,
            iporValueAfterOpenPosition,
            params.openTimestamp,
            { from: userOne }
        );

        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        await data.warren.test_updateIndex(
            params.asset,
            iporValueAfterOpenPosition,
            endTimestamp - 1,
            { from: userOne }
        );

        //when
        await data.milton.test_closePosition(1, endTimestamp, {
            from: closerUserAddress,
        });

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            openerUserAddress,
            closerUserAddress,
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
            from: openerUserAddress,
        };
        await assertSoap(soapParams);
    });

    it("should open many positions and arrays with ids have correct state, one user", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress,
        };
        await data.warren.test_updateIndex(
            derivativeParams.asset,
            iporValueBeforeOpenPosition,
            derivativeParams.openTimestamp,
            { from: userOne }
        );

        let expectedUserDerivativeIdsLength = 3;
        let expectedDerivativeIdsLength = 3;

        await data.joseph.test_provideLiquidity(
            derivativeParams.asset,
            BigInt(3) * testUtils.USD_14_000_18DEC,
            derivativeParams.openTimestamp,
            { from: liquidityProvider }
        );

        //when
        await openPositionFunc(derivativeParams);
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);

        //then
        let actualUserDerivativeIds =
            await testData.miltonStorage.getUserDerivativeIds(
                openerUserAddress
            );
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        assert(
            expectedUserDerivativeIdsLength === actualUserDerivativeIds.length,
            `Incorrect user derivative ids length actual: ${actualUserDerivativeIds.length}, expected: ${expectedUserDerivativeIdsLength}`
        );
        assert(
            expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        );

        await assertMiltonDerivativeItem(testData, 1, 0, 0);
        await assertMiltonDerivativeItem(testData, 2, 1, 1);
        await assertMiltonDerivativeItem(testData, 3, 2, 2);
    });

    it("should open many positions and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await data.warren.test_updateIndex(
            derivativeParams.asset,
            iporValueBeforeOpenPosition,
            derivativeParams.openTimestamp,
            { from: userOne }
        );

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 1;
        let expectedDerivativeIdsLength = 3;

        await data.joseph.test_provideLiquidity(
            derivativeParams.asset,
            BigInt(3) * testUtils.USD_14_000_18DEC,
            derivativeParams.openTimestamp,
            { from: liquidityProvider }
        );

        //when
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userThree);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        assert(
            expectedUserDerivativeIdsLengthFirst ===
                actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        );
        assert(
            expectedUserDerivativeIdsLengthSecond ===
                actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        );
        assert(
            expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        );

        await assertMiltonDerivativeItem(testData, 1, 0, 0);
        await assertMiltonDerivativeItem(testData, 2, 1, 0);
        await assertMiltonDerivativeItem(testData, 3, 2, 1);
    });

    it("should open many positions and close one position and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await data.warren.test_updateIndex(
            derivativeParams.asset,
            iporValueBeforeOpenPosition,
            derivativeParams.openTimestamp,
            { from: userOne }
        );

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 2;

        await data.joseph.test_provideLiquidity(
            derivativeParams.asset,
            BigInt(3) * testUtils.USD_14_000_18DEC,
            derivativeParams.openTimestamp,
            { from: liquidityProvider }
        );

        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton.test_closePosition(
            2,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_25_DAYS_IN_SECONDS,
            { from: userThree }
        );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userThree);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        assert(
            expectedUserDerivativeIdsLengthFirst ===
                actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        );
        assert(
            expectedUserDerivativeIdsLengthSecond ===
                actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        );
        assert(
            expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        );

        await assertMiltonDerivativeItem(testData, 1, 0, 0);
        await assertMiltonDerivativeItem(testData, 3, 1, 1);
    });

    it("should open many positions and close two positions and arrays with ids have correct state, two users", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo,
        };
        await data.warren.test_updateIndex(
            derivativeParams.asset,
            iporValueBeforeOpenPosition,
            derivativeParams.openTimestamp,
            { from: userOne }
        );

        let expectedUserDerivativeIdsLengthFirst = 1;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 1;

        await data.joseph.test_provideLiquidity(
            derivativeParams.asset,
            BigInt(3) * testUtils.USD_14_000_18DEC,
            derivativeParams.openTimestamp,
            { from: liquidityProvider }
        );

        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton.test_closePosition(
            2,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_25_DAYS_IN_SECONDS,
            { from: userThree }
        );
        await data.milton.test_closePosition(
            3,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_25_DAYS_IN_SECONDS,
            { from: userTwo }
        );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userThree);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        assert(
            expectedUserDerivativeIdsLengthFirst ===
                actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        );
        assert(
            expectedUserDerivativeIdsLengthSecond ===
                actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        );
        assert(
            expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        );

        await assertMiltonDerivativeItem(testData, 1, 0, 0);
    });

    it("should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await data.joseph.test_provideLiquidity(
            derivativeParams.asset,
            BigInt(2) * testUtils.USD_14_000_18DEC,
            derivativeParams.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            derivativeParams.asset,
            iporValueBeforeOpenPosition,
            derivativeParams.openTimestamp,
            { from: userOne }
        );

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton.test_closePosition(
            1,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_25_DAYS_IN_SECONDS,
            { from: userThree }
        );
        await data.milton.test_closePosition(
            2,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_50_DAYS_IN_SECONDS,
            { from: userThree }
        );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        assert(
            expectedUserDerivativeIdsLengthFirst ===
                actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        );
        assert(
            expectedUserDerivativeIdsLengthSecond ===
                actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        );
        assert(
            expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        );
    });

    it("should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1 with minus 3", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await data.joseph.test_provideLiquidity(
            derivativeParams.asset,
            BigInt(2) * testUtils.USD_14_000_18DEC,
            derivativeParams.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            derivativeParams.asset,
            iporValueBeforeOpenPosition,
            derivativeParams.openTimestamp,
            { from: userOne }
        );

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp =
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS -
            3;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton.test_closePosition(
            1,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_25_DAYS_IN_SECONDS,
            { from: userThree }
        );
        await data.milton.test_closePosition(
            2,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_50_DAYS_IN_SECONDS,
            { from: userThree }
        );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        assert(
            expectedUserDerivativeIdsLengthFirst ===
                actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        );
        assert(
            expectedUserDerivativeIdsLengthSecond ===
                actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        );
        assert(
            expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        );
    });

    it("should open two positions and close one position - Arithmetic overflow - last byte difference - case 1", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.USD_10_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree,
        };
        await data.joseph.test_provideLiquidity(
            derivativeParams.asset,
            BigInt(2) * testUtils.USD_14_000_18DEC,
            derivativeParams.openTimestamp,
            { from: liquidityProvider }
        );
        await data.warren.test_updateIndex(
            derivativeParams.asset,
            iporValueBeforeOpenPosition,
            derivativeParams.openTimestamp,
            { from: userOne }
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
            derivativeParams.openTimestamp +
            testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        derivativeParams.direction = 0;
        await openPositionFunc(derivativeParams);

        await data.milton.test_closePosition(
            1,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_25_DAYS_IN_SECONDS,
            { from: userThree }
        );

        //when
        await data.milton.test_closePosition(
            2,
            derivativeParams.openTimestamp +
                testUtils.PERIOD_50_DAYS_IN_SECONDS,
            { from: userThree }
        );

        //then
        let actualUserDerivativeIdsFirst =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond =
            await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualDerivativeIds =
            await testData.miltonStorage.getDerivativeIds();

        assert(
            expectedUserDerivativeIdsLengthFirst ===
                actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`
        );
        assert(
            expectedUserDerivativeIdsLengthSecond ===
                actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`
        );
        assert(
            expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`
        );
    });

    it("should calculate income tax, 5%, not owner, Milton loses, user earns, |I| < D", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_5_18DEC
        );

        let incomeTax = BigInt("419666206858875426943");
        let incomeTaxWad = BigInt("419666206858875426943");
        let interestAmount = BigInt("8393324137177508538862");
        let interestAmountWad = BigInt("8393324137177508538862");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 5%, Milton loses, user earns, |I| > D", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_5_18DEC
        );

        let incomeTax = BigInt("497008973080757726820");
        let incomeTaxWad = BigInt("497008973080757726820");

        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 5%, Milton earns, user loses, |I| < D", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_5_18DEC
        );

        let incomeTax = BigInt("394883841625807510682");
        let incomeTaxWad = BigInt("394883841625807510682");
        let interestAmount = BigInt("7897676832516150213639");
        let interestAmountWad = BigInt("7897676832516150213639");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 5%, Milton earns, user loses, |I| > D", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
    });

    it("should calculate income tax, 5%, Milton earns, user loses, |I| > D", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin
        );

        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_5_18DEC
        );

        let incomeTax = BigInt("497008973080757726820");
        let incomeTaxWad = BigInt("497008973080757726820");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 100%, Milton loses, user earns, |I| < D", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_100_18DEC
        );

        let incomeTax = BigInt("8393324137177508538862");
        let incomeTaxWad = BigInt("8393324137177508538862");
        let interestAmount = BigInt("8393324137177508538862");
        let interestAmountWad = BigInt("8393324137177508538862");

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 100%, Milton loses, user earns, |I| > D", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_100_18DEC
        );

        let incomeTax = BigInt("9940179461615154536391");
        let incomeTaxWad = BigInt("9940179461615154536391");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonLostAndUserEarn(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 100%, Milton earns, user loses, |I| < D, to low liquidity pool", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_100_18DEC
        );
        let incomeTax = BigInt("7897676832516150213639");
        let incomeTaxWad = BigInt("7897676832516150213639");
        let interestAmount = BigInt("7897676832516150213639");
        let interestAmountWad = BigInt("7897676832516150213639");

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_120_18DEC,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_10_18DEC
        );
    });

    it("should calculate income tax, 100%, Milton earns, user loses, |I| > D, to low liquidity pool", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
    });

    it("should calculate income tax, 100%, Milton earns, user loses, |I| > D, to low liquidity pool", async () => {
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_100_18DEC
        );

        let incomeTax = BigInt("9940179461615154536391");
        let incomeTaxWad = BigInt("9940179461615154536391");
        let interestAmount = testUtils.TC_COLLATERAL_18DEC;
        let interestAmountWad = testUtils.TC_COLLATERAL_18DEC;

        await testCaseWhenMiltonEarnAndUserLost(
            testData,
            testData.tokenDai.address,
            testUtils.USD_10_18DEC,
            1,
            userTwo,
            userThree,
            testUtils.PERCENTAGE_5_18DEC,
            testUtils.PERCENTAGE_160_18DEC,
            testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            null,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );

        await testData.iporAssetConfigurationDai.setIncomeTaxPercentage(
            testUtils.PERCENTAGE_10_18DEC
        );
    });

    it("should open pay fixed position, DAI, custom Opening Fee for Treasury 50%", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        await testData.iporAssetConfigurationDai.setOpeningFeeForTreasuryPercentage(
            BigInt("50000000000000000")
        );

        let expectedOpeningFeeTotalBalanceWad = testUtils.TC_OPENING_FEE_18DEC;
        let expectedTreasuryTotalBalanceWad = BigInt("1491026919242273180");

        let miltonBalanceBeforePayoutWad = testUtils.USD_14_000_18DEC;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + BigInt("28329511465603190429");
        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayoutWad,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        //when
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
        );

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidityPoolTotalBalanceWad = BigInt(
            balance.liquidityPool
        );
        const actualTreasuryTotalBalanceWad = BigInt(balance.treasury);

        assert(
            expectedOpeningFeeTotalBalanceWad === actualOpeningFeeTotalBalance,
            `Incorrect opening fee total balance for ${params.asset}, actual:  ${actualOpeningFeeTotalBalance},
            expected: ${expectedOpeningFeeTotalBalanceWad}`
        );
        assert(
            expectedLiquidityPoolTotalBalanceWad ===
                actualLiquidityPoolTotalBalanceWad,
            `Incorrect Liquidity Pool total balance for ${params.asset}, actual:  ${actualLiquidityPoolTotalBalanceWad},
            expected: ${expectedLiquidityPoolTotalBalanceWad}`
        );
        assert(
            expectedTreasuryTotalBalanceWad === actualTreasuryTotalBalanceWad,
            `Incorrect Treasury total balance for ${params.asset}, actual:  ${actualTreasuryTotalBalanceWad},
            expected: ${expectedTreasuryTotalBalanceWad}`
        );

        await testData.iporAssetConfigurationDai.setOpeningFeeForTreasuryPercentage(
            ZERO
        );
    });

    it("should open pay fixed position, DAI, custom Opening Fee for Treasury 25%", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        await testData.iporAssetConfigurationDai.setOpeningFeeForTreasuryPercentage(
            BigInt("25000000000000000")
        );

        let expectedOpeningFeeTotalBalanceWad = testUtils.TC_OPENING_FEE_18DEC;
        let expectedTreasuryTotalBalanceWad = BigInt("745513459621136590");

        let miltonBalanceBeforePayoutWad = testUtils.USD_14_000_18DEC;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + BigInt("29075024925224327019");
        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayoutWad,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        //when
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
        );

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidityPoolTotalBalanceWad = BigInt(
            balance.liquidityPool
        );
        const actualTreasuryTotalBalanceWad = BigInt(balance.treasury);

        assert(
            expectedOpeningFeeTotalBalanceWad === actualOpeningFeeTotalBalance,
            `Incorrect opening fee total balance for ${params.asset}, actual:  ${actualOpeningFeeTotalBalance},
            expected: ${expectedOpeningFeeTotalBalanceWad}`
        );
        assert(
            expectedLiquidityPoolTotalBalanceWad ===
                actualLiquidityPoolTotalBalanceWad,
            `Incorrect Liquidity Pool total balance for ${params.asset}, actual:  ${actualLiquidityPoolTotalBalanceWad},
            expected: ${expectedLiquidityPoolTotalBalanceWad}`
        );
        assert(
            expectedTreasuryTotalBalanceWad === actualTreasuryTotalBalanceWad,
            `Incorrect Treasury total balance for ${params.asset}, actual:  ${actualTreasuryTotalBalanceWad},
            expected: ${expectedTreasuryTotalBalanceWad}`
        );

        await testData.iporAssetConfigurationDai.setOpeningFeeForTreasuryPercentage(
            ZERO
        );
    });

    it("should NOT transfer Publication Fee to Charlie Treasury - caller not publication fee transferer", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
        );

        //when
        await testUtils.assertError(
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
        );

        await data.iporConfiguration.setMiltonPublicationFeeTransferer(admin);

        //when
        await testUtils.assertError(
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("CHARLIE_TREASURER_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("CHARLIE_TREASURER_ROLE"),
            admin
        );
        await data.iporConfiguration.grantRole(
            keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"),
            admin
        );
        await data.iporConfiguration.grantRole(
            keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"),
            admin
        );

        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
        );

        await data.iporConfiguration.setMiltonPublicationFeeTransferer(admin);
        await testData.iporAssetConfigurationDai.setCharlieTreasurer(userThree);

        const transferedAmount = BigInt("100");

        //when
        await data.milton.transferPublicationFee(
            testData.tokenDai.address,
            transferedAmount
        );

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

        let expectedErc20BalanceCharlieTreasurer =
            testUtils.USER_SUPPLY_18_DECIMALS + transferedAmount;
        let actualErc20BalanceCharlieTreasurer = BigInt(
            await testData.tokenDai.balanceOf(userThree)
        );

        let expectedErc20BalanceMilton =
            testUtils.USD_14_000_18DEC +
            testUtils.USD_10_000_18DEC -
            transferedAmount;
        let actualErc20BalanceMilton = BigInt(
            await testData.tokenDai.balanceOf(data.milton.address)
        );

        let expectedPublicationFeeBalanceMilton =
            testUtils.USD_10_18DEC - transferedAmount;
        const actualPublicationFeeBalanceMilton = BigInt(
            balance.iporPublicationFee
        );

        assert(
            expectedErc20BalanceCharlieTreasurer ===
                actualErc20BalanceCharlieTreasurer,
            `Incorrect ERC20 Charlie Treasurer balance for ${params.asset}, actual:  ${actualErc20BalanceCharlieTreasurer},
                expected: ${expectedErc20BalanceCharlieTreasurer}`
        );

        assert(
            expectedErc20BalanceMilton === actualErc20BalanceMilton,
            `Incorrect ERC20 Milton balance for ${params.asset}, actual:  ${actualErc20BalanceMilton},
                expected: ${expectedErc20BalanceMilton}`
        );

        assert(
            expectedPublicationFeeBalanceMilton ===
                actualPublicationFeeBalanceMilton,
            `Incorrect Milton balance for ${params.asset}, actual:  ${actualPublicationFeeBalanceMilton},
                expected: ${expectedPublicationFeeBalanceMilton}`
        );
    });

    it("should NOT open pay fixed position, DAI, collateralization factor too low", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt(500),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        //when
        await testUtils.assertError(
            //when
            data.milton.test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction,
                { from: userTwo }
            ),
            //then
            "IPOR_12"
        );
    });

    it("should NOT open pay fixed position, DAI, collateralization factor too high", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt("50000000000000000001"),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        //when
        await testUtils.assertError(
            //when
            data.milton.test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction,
                { from: userTwo }
            ),
            //then
            "IPOR_34"
        );
    });

    it("should open pay fixed position, DAI, custom collateralization factor - simple case 1", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );

        const params = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt("15125000000000000000"),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        await data.joseph.test_provideLiquidity(
            params.asset,
            testUtils.USD_14_000_18DEC,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        //when
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
        );

        //then
        let actualDerivativeItem =
            await testData.miltonStorage.getDerivativeItem(1);
        let actualNotionalAmount = BigInt(
            actualDerivativeItem.item.notionalAmount
        );
        let expectedNotionalAmount = BigInt("150115102721401640058243");

        assert(
            expectedNotionalAmount === actualNotionalAmount,
            `Incorrect notional amount for ${params.asset}, actual:  ${actualNotionalAmount},
            expected: ${expectedNotionalAmount}`
        );
    });

    it("should open pay fixed position - liquidity pool utilisation not exceeded, custom utilisation", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        let closerUserEarned = ZERO;
        let openerUserLost =
            testUtils.TC_OPENING_FEE_18DEC +
            testUtils.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC +
            testUtils.TC_COLLATERAL_18DEC;

        let closerUserLost = openerUserLost;
        let openerUserEarned = closerUserEarned;

        let expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            testUtils.USER_SUPPLY_18_DECIMALS +
            openerUserEarned -
            openerUserLost;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose =
            testUtils.USER_SUPPLY_18_DECIMALS +
            closerUserEarned -
            closerUserLost;

        let miltonBalanceBeforePayoutWad =
            testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayoutWad,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        let expectedMiltonUnderlyingTokenBalance =
            miltonBalanceBeforePayoutWad +
            testUtils.TC_OPENING_FEE_18DEC +
            testUtils.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
            testUtils.TC_COLLATERAL_18DEC +
            testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;

        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad + testUtils.TC_OPENING_FEE_18DEC;

        let oldLiquidityPoolMaxUtilizationPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();

        let liquidityPoolMaxUtilizationEdge = BigInt(718503678605107622);

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            liquidityPoolMaxUtilizationEdge
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        //when
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
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
            testUtils.TC_COLLATERAL_18DEC,
            testUtils.USD_20_18DEC,
            ZERO
        );

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            oldLiquidityPoolMaxUtilizationPercentage
        );
    });

    it("should NOT open pay fixed position - when new position opened then liquidity pool utilisation exceeded, custom utilisation", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        let miltonBalanceBeforePayoutWad =
            testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayoutWad,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        let oldLiquidityPoolMaxUtilizationPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();

        let liquidityPoolMaxUtilizationEdge = BigInt(608038055741904007);

        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            liquidityPoolMaxUtilizationEdge
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        //when
        await testUtils.assertError(
            //when
            data.milton.test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction,
                { from: userTwo }
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin
        );
        await testData.iporAssetConfigurationDai.grantRole(
            keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"),
            admin
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        let oldLiquidityPoolMaxUtilizationPercentage =
            await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();
        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        let miltonBalanceBeforePayoutWad = testUtils.USD_14_000_18DEC;
        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayoutWad,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        let liquiditiPoolMaxUtilizationEdge = BigInt(758503678605107622);
        await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
            liquiditiPoolMaxUtilizationEdge
        );

        //First open position not exceeded liquidity utilization
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: userTwo }
        );

        //when
        //Second open position exceeded liquidity utilization
        await testUtils.assertError(
            //when
            data.milton.test_openPosition(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction,
                { from: userTwo }
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
    //     let testData = await testUtils.prepareTestData(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["DAI"],
    //         data
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
    //         admin
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
    //         admin
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
    //         admin
    //     );
    //     await testData.iporAssetConfigurationDai.grantRole(
    //         keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"),
    //         admin
    //     );
    //     await testUtils.prepareApproveForUsers(
    //         [userOne, userTwo, userThree, liquidityProvider],
    //         "DAI",
    //         data,
    //         testData
    //     );
    //     await testUtils.setupTokenDaiInitialValuesForUsers(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         testData
    //     );
    //     const params = testUtils.getPayFixedDerivativeParamsDAICase1(
    //         userTwo,
    //         testData
    //     );

    //     let oldLiquidityPoolMaxUtilizationPercentage =
    //         await testData.iporAssetConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();
    //     let oldOpeningFeePercentage =
    //         await testData.iporAssetConfigurationDai.getOpeningFeePercentage();

    //     await data.warren.test_updateIndex(
    //         params.asset,
    //         testUtils.PERCENTAGE_3_18DEC,
    //         params.openTimestamp,
    //         { from: userOne }
    //     );

    //     await testData.iporAssetConfigurationDai.setOpeningFeePercentage(ZERO);
    //     //very high value
    //     await testData.iporAssetConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(
    //         BigInt(99999999999999999999999999999999999999999)
    //     );

    //     await testUtils.assertError(
    //         //when
    //         data.milton.test_openPosition(
    //             params.openTimestamp,
    //             params.asset,
    //             params.totalAmount,
    //             params.slippageValue,
    //             params.collateralizationFactor,
    //             params.direction,
    //             { from: userTwo }
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
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
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
            testUtils.USD_10_18DEC,
            0,
            userTwo,
            userTwo,
            testUtils.PERCENTAGE_3_18DEC,
            testUtils.PERCENTAGE_3_18DEC,
            0,
            0,
            testUtils.ZERO,
            testUtils.ZERO,
            incomeTaxWad,
            testUtils.ZERO,
            veryLongTimeAgoTimestamp,
            incomeTax,
            incomeTaxWad,
            interestAmount,
            interestAmountWad
        );
    });

    it("should NOT open pay fixed position - asset address not supported", async () => {
        //given

        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );

        let miltonBalanceBeforePayoutWad = testUtils.USD_14_000_18DEC;
        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayoutWad,
            params.openTimestamp,
            { from: liquidityProvider }
        );

        //when
        await testUtils.assertError(
            //when
            data.milton.test_openPosition(
                params.openTimestamp,
                liquidityProvider,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor,
                params.direction,
                { from: userTwo }
            ),
            //then
            "IPOR_39"
        );
    });

    it("should calculate Position Value - simple case 1", async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data
        );
        await testUtils.prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await testUtils.setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            testData
        );
        const params = testUtils.getPayFixedDerivativeParamsDAICase1(
            userTwo,
            testData
        );

        await data.warren.test_updateIndex(
            params.asset,
            testUtils.PERCENTAGE_3_18DEC,
            params.openTimestamp,
            { from: userOne }
        );
        let miltonBalanceBeforePayoutWad = testUtils.USD_14_000_18DEC;
        await data.joseph.test_provideLiquidity(
            params.asset,
            miltonBalanceBeforePayoutWad,
            params.openTimestamp,
            { from: liquidityProvider }
        );
        await openPositionFunc(params);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let expectedPositionValue = BigInt("-38126715743181445978");

        //when
        let actualPositionValue = BigInt(
            await data.milton.test_calculatePositionValue(
                params.openTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS,
                derivativeItem.item
            )
        );

        //then
        assert(
            expectedPositionValue === actualPositionValue,
            `Incorrect position value, actual: ${actualPositionValue}, expected: ${expectedPositionValue}`
        );
    });

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

    const calculateSoap = async (params) => {
        return await data.milton.test_calculateSoap.call(
            params.asset,
            params.calculateTimestamp,
            { from: params.from }
        );
    };

    const openPositionFunc = async (params) => {
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction,
            { from: params.from }
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
        assert(
            BigInt(expectedIdsIndex) === BigInt(actualDerivativeItem.idsIndex),
            `Incorrect idsIndex for derivative id ${actualDerivativeItem.item.id} actual: ${actualDerivativeItem.idsIndex}, expected: ${expectedIdsIndex}`
        );
        assert(
            BigInt(expectedUserDerivativeIdsIndex) ===
                BigInt(actualDerivativeItem.userDerivativeIdsIndex),
            `Incorrect userDerivativeIdsIndex for derivative id ${actualDerivativeItem.item.id} actual: ${actualDerivativeItem.userDerivativeIdsIndex}, expected: ${expectedUserDerivativeIdsIndex}`
        );
    };

    //TODO: add to every test..
    const assertDerivative = async (derivativeId, expectedDerivative) => {
        // let actualDerivative = await data.milton.getOpenPosition(derivativeId);
        //
        // assertDerivativeItem('ID', expectedDerivative.id, actualDerivative.id);
        // assertDerivativeItem('State', expectedDerivative.state, actualDerivative.state);
        // assertDerivativeItem('Buyer', expectedDerivative.buyer, actualDerivative.buyer);
        // assertDerivativeItem('Asset', expectedDerivative.asset, actualDerivative.asset);
        // assertDerivativeItem('Direction', expectedDerivative.direction, actualDerivative.direction);
        // assertDerivativeItem('Deposit Amount', expectedDerivative.depositAmount, actualDerivative.depositAmount);
        // assertDerivativeItem('Liquidation Deposit Amount', expectedDerivative.fee.liquidationDepositAmount, actualDerivative.fee.liquidationDepositAmount);
        // assertDerivativeItem('Opening Amount Fee', expectedDerivative.fee.openingAmount, actualDerivative.fee.openingAmount);
        // assertDerivativeItem('IPOR Publication Amount Fee', expectedDerivative.fee.iporPublicationAmount, actualDerivative.fee.iporPublicationAmount);
        // assertDerivativeItem('Spread Percentage Fee', expectedDerivative.fee.spreadPercentage, actualDerivative.fee.spreadPercentage);
        // assertDerivativeItem('Collateralization', expectedDerivative.collateralization, actualDerivative.collateralization);
        // assertDerivativeItem('Notional Amount', expectedDerivative.notionalAmount, actualDerivative.notionalAmount);
        // // assertDerivativeItem('Derivative starting timestamp', expectedDerivative.startingTimestamp, actualDerivative.startingTimestamp);
        // // assertDerivativeItem('Derivative ending timestamp', expectedDerivative.endingTimestamp, actualDerivative.endingTimestamp);
        // assertDerivativeItem('IPOR Index Value', expectedDerivative.indicator.iporIndexValue, actualDerivative.indicator.iporIndexValue);
        // assertDerivativeItem('IBT Price', expectedDerivative.indicator.ibtPrice, actualDerivative.indicator.ibtPrice);
        // assertDerivativeItem('IBT Quantity', expectedDerivative.indicator.ibtQuantity, actualDerivative.indicator.ibtQuantity);
        // assertDerivativeItem('Fixed Interest Rate', expectedDerivative.indicator.fixedInterestRate, actualDerivative.indicator.fixedInterestRate);
        // assertDerivativeItem('SOAP', expectedDerivative.indicator.soap, actualDerivative.indicator.soap);
    };

    const testCaseWhenMiltonEarnAndUserLost = async function (
        testData,
        asset,
        collateralizationFactor,
        direction,
        openerUserAddress,
        closerUserAddress,
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
        let miltonBalanceBeforePayoutWad =
            testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
        let openerUserLost = null;
        let openerUserEarned = null;
        let closerUserLost = null;
        let closerUserEarned = null;
        let expectedOpenerUserUnderlyingTokenBalanceAfterClose = null;
        let expectedCloserUserUnderlyingTokenBalanceAfterClose = null;
        let expectedMiltonUnderlyingTokenBalance = null;
        let expectedLiquidityPoolTotalBalanceWad =
            miltonBalanceBeforePayoutWad +
            testUtils.TC_OPENING_FEE_18DEC +
            interestAmountWad -
            incomeTaxWad;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout =
                testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                testUtils.TC_OPENING_FEE_18DEC +
                testUtils.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC +
                interestAmount;

            if (openerUserAddress === closerUserAddress) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                testUtils.USER_SUPPLY_18_DECIMALS +
                openerUserEarned -
                openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                testUtils.USER_SUPPLY_18_DECIMALS +
                closerUserEarned -
                closerUserLost;
            expectedMiltonUnderlyingTokenBalance =
                testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
                testUtils.TC_OPENING_FEE_18DEC +
                testUtils.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                interestAmount;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            miltonBalanceBeforePayout =
                testUtils.TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
            closerUserEarned = testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
            openerUserLost =
                testUtils.TC_OPENING_FEE_6DEC +
                testUtils.TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC +
                interestAmount;

            if (openerUserAddress === closerUserAddress) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                testUtils.USER_SUPPLY_6_DECIMALS +
                openerUserEarned -
                openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                testUtils.USER_SUPPLY_6_DECIMALS +
                closerUserEarned -
                closerUserLost;
            expectedMiltonUnderlyingTokenBalance =
                testUtils.TC_LP_BALANCE_BEFORE_CLOSE_6DEC +
                testUtils.TC_OPENING_FEE_6DEC +
                testUtils.TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                interestAmount;
        }

        await exetuceClosePositionTestCase(
            testData,
            asset,
            collateralizationFactor,
            direction,
            openerUserAddress,
            closerUserAddress,
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
        openerUserAddress,
        closerUserAddress,
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
        let miltonBalanceBeforePayoutWad =
            testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
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
            testUtils.TC_OPENING_FEE_18DEC;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            miltonBalanceBeforePayout =
                testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC;
            closerUserEarned = testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
            openerUserLost =
                testUtils.TC_OPENING_FEE_18DEC +
                testUtils.TC_IPOR_PUBLICATION_AMOUNT_18DEC +
                testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC -
                interestAmount +
                incomeTax;

            if (openerUserAddress === closerUserAddress) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedMiltonUnderlyingTokenBalance =
                testUtils.TC_LP_BALANCE_BEFORE_CLOSE_18DEC +
                testUtils.TC_OPENING_FEE_18DEC +
                testUtils.TC_IPOR_PUBLICATION_AMOUNT_18DEC -
                interestAmount +
                incomeTax;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                testUtils.USER_SUPPLY_18_DECIMALS +
                openerUserEarned -
                openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                testUtils.USER_SUPPLY_18_DECIMALS +
                closerUserEarned -
                closerUserLost;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            miltonBalanceBeforePayout =
                testUtils.TC_LP_BALANCE_BEFORE_CLOSE_6DEC;
            closerUserEarned = testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC;
            openerUserLost =
                testUtils.TC_OPENING_FEE_6DEC +
                testUtils.TC_IPOR_PUBLICATION_AMOUNT_6DEC +
                testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC -
                interestAmount +
                incomeTax;

            if (openerUserAddress === closerUserAddress) {
                closerUserLost = openerUserLost;
                openerUserEarned = closerUserEarned;
            } else {
                closerUserLost = ZERO;
                openerUserEarned = ZERO;
            }

            expectedMiltonUnderlyingTokenBalance =
                testUtils.TC_LP_BALANCE_BEFORE_CLOSE_6DEC +
                testUtils.TC_OPENING_FEE_6DEC +
                testUtils.TC_IPOR_PUBLICATION_AMOUNT_6DEC -
                interestAmount +
                incomeTax;
            expectedOpenerUserUnderlyingTokenBalanceAfterClose =
                testUtils.USER_SUPPLY_6_DECIMALS +
                openerUserEarned -
                openerUserLost;
            expectedCloserUserUnderlyingTokenBalanceAfterClose =
                testUtils.USER_SUPPLY_6_DECIMALS +
                closerUserEarned -
                closerUserLost;
        }

        await exetuceClosePositionTestCase(
            testData,
            asset,
            collateralizationFactor,
            direction,
            openerUserAddress,
            closerUserAddress,
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
        openerUserAddress,
        closerUserAddress,
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
            totalAmount = testUtils.USD_10_000_18DEC;
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            totalAmount = testUtils.USD_10_000_6DEC;
        }

        const params = {
            asset: asset,
            totalAmount: totalAmount,
            slippageValue: 3,
            collateralizationFactor: collateralizationFactor,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUserAddress,
        };

        if (providedLiquidityAmount != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await data.joseph.test_provideLiquidity(
                params.asset,
                providedLiquidityAmount,
                params.openTimestamp,
                { from: liquidityProvider }
            );
        }

        await data.warren.test_updateIndex(
            params.asset,
            iporValueBeforeOpenPosition,
            params.openTimestamp,
            { from: userOne }
        );
        await openPositionFunc(params);
        await data.warren.test_updateIndex(
            params.asset,
            iporValueAfterOpenPosition,
            params.openTimestamp,
            { from: userOne }
        );

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;

        //when
        await data.milton.test_closePosition(1, endTimestamp, {
            from: closerUserAddress,
        });

        //then
        await assertExpectedValues(
            testData,
            params.asset,
            openerUserAddress,
            closerUserAddress,
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
            from: openerUserAddress,
        };
        await assertSoap(soapParams);
    };

    const assertExpectedValues = async function (
        testData,
        asset,
        openerUserAddress,
        closerUserAddress,
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
        assert(
            expectedOpenedPositions === actualOpenPositionsVol,
            `Incorrect number of opened derivatives, actual:  ${actualOpenPositionsVol}, expected: ${expectedOpenedPositions}`
        );

        let expectedOpeningFeeTotalBalanceWad = testUtils.TC_OPENING_FEE_18DEC;
        let expectedPublicationFeeTotalBalanceWad = testUtils.USD_10_18DEC;
        let openerUserUnderlyingTokenBalanceBeforePayout = null;
        let closerUserUnderlyingTokenBalanceBeforePayout = null;
        let miltonUnderlyingTokenBalanceAfterPayout = null;
        let openerUserUnderlyingTokenBalanceAfterPayout = null;
        let closerUserUnderlyingTokenBalanceAfterPayout = null;

        if (testData.tokenDai && asset === testData.tokenDai.address) {
            openerUserUnderlyingTokenBalanceBeforePayout =
                testUtils.USD_10_000_000_18DEC;
            closerUserUnderlyingTokenBalanceBeforePayout =
                testUtils.USD_10_000_000_18DEC;
            miltonUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(data.milton.address)
            );
            openerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(openerUserAddress)
            );
            closerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenDai.balanceOf(closerUserAddress)
            );
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            openerUserUnderlyingTokenBalanceBeforePayout =
                testUtils.USD_10_000_000_6DEC;
            closerUserUnderlyingTokenBalanceBeforePayout =
                testUtils.USD_10_000_000_6DEC;
            miltonUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(data.milton.address)
            );
            openerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(openerUserAddress)
            );
            closerUserUnderlyingTokenBalanceAfterPayout = BigInt(
                await testData.tokenUsdt.balanceOf(closerUserAddress)
            );
        }

        await assertBalances(
            testData,
            asset,
            openerUserAddress,
            closerUserAddress,
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

        if (openerUserAddress === closerUserAddress) {
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

        assert(
            expectedSumOfBalancesBeforePayout === actualSumOfBalances,
            `Incorrect balance between AMM Balance and Users Balance for asset ${asset}, actual: ${actualSumOfBalances}, expected ${expectedSumOfBalancesBeforePayout}`
        );
    };

    const assertSoap = async (params) => {
        let actualSoapStruct = await calculateSoap(params);
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then
        assert(
            params.expectedSoap === actualSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`
        );
    };

    const assertBalances = async (
        testData,
        asset,
        openerUserAddress,
        closerUserAddress,
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
                await testData.tokenDai.balanceOf(openerUserAddress)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenDai.balanceOf(closerUserAddress)
            );
        }

        if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
            actualOpenerUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(openerUserAddress)
            );
            actualCloserUserUnderlyingTokenBalance = BigInt(
                await testData.tokenUsdt.balanceOf(closerUserAddress)
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
            assert(
                actualMiltonUnderlyingTokenBalance ===
                    expectedMiltonUnderlyingTokenBalance,
                `Incorrect underlying token balance for ${asset} in Milton address, actual: ${actualMiltonUnderlyingTokenBalance}, expected: ${expectedMiltonUnderlyingTokenBalance}`
            );
        }

        if (expectedOpenerUserUnderlyingTokenBalance != null) {
            assert(
                actualOpenerUserUnderlyingTokenBalance ===
                    expectedOpenerUserUnderlyingTokenBalance,
                `Incorrect token balance for ${asset} in Opener User address, actual: ${actualOpenerUserUnderlyingTokenBalance}, expected: ${expectedOpenerUserUnderlyingTokenBalance}`
            );
        }

        if (expectedCloserUserUnderlyingTokenBalance != null) {
            assert(
                actualCloserUserUnderlyingTokenBalance ===
                    expectedCloserUserUnderlyingTokenBalance,
                `Incorrect token balance for ${asset} in Closer User address, actual: ${actualCloserUserUnderlyingTokenBalance}, expected: ${expectedCloserUserUnderlyingTokenBalance}`
            );
        }

        if (expectedDerivativesTotalBalanceWad != null) {
            assert(
                expectedDerivativesTotalBalanceWad ===
                    actualDerivativesTotalBalance,
                `Incorrect derivatives total balance for ${asset}, actual:  ${actualDerivativesTotalBalance}, expected: ${expectedDerivativesTotalBalanceWad}`
            );
        }

        if (expectedOpeningFeeTotalBalanceWad != null) {
            assert(
                expectedOpeningFeeTotalBalanceWad ===
                    actualOpeningFeeTotalBalance,
                `Incorrect opening fee total balance for ${asset}, actual:  ${actualOpeningFeeTotalBalance}, expected: ${expectedOpeningFeeTotalBalanceWad}`
            );
        }

        if (expectedLiquidationDepositTotalBalanceWad !== null) {
            assert(
                expectedLiquidationDepositTotalBalanceWad ===
                    actualLiquidationDepositTotalBalance,
                `Incorrect liquidation deposit fee total balance for ${asset}, actual:  ${actualLiquidationDepositTotalBalance}, expected: ${expectedLiquidationDepositTotalBalanceWad}`
            );
        }

        if (expectedPublicationFeeTotalBalanceWad != null) {
            assert(
                expectedPublicationFeeTotalBalanceWad ===
                    actualPublicationFeeTotalBalance,
                `Incorrect ipor publication fee total balance for ${asset}, actual: ${actualPublicationFeeTotalBalance}, expected: ${expectedPublicationFeeTotalBalanceWad}`
            );
        }

        if (expectedLiquidityPoolTotalBalanceWad != null) {
            assert(
                expectedLiquidityPoolTotalBalanceWad ===
                    actualLiquidityPoolTotalBalanceWad,
                `Incorrect Liquidity Pool total balance for ${asset}, actual:  ${actualLiquidityPoolTotalBalanceWad}, expected: ${expectedLiquidityPoolTotalBalanceWad}`
            );
        }

        if (expectedTreasuryTotalBalanceWad != null) {
            assert(
                expectedTreasuryTotalBalanceWad ===
                    actualTreasuryTotalBalanceWad,
                `Incorrect Treasury total balance for ${asset}, actual:  ${actualTreasuryTotalBalanceWad}, expected: ${expectedTreasuryTotalBalanceWad}`
            );
        }
    };
});
