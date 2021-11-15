const keccak256 = require('keccak256')
const testUtils = require("./TestUtils.js");
const {ZERO, USER_SUPPLY_18_DECIMALS, USER_SUPPLY_6_DECIMALS} = require("./TestUtils");

contract('Joseph', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let data = null;
    let testData

    before(async () => {
        data = await testUtils.prepareDataForBefore(accounts);
    });

    beforeEach(async () => {
        testData = await testUtils.prepareDataForBeforeEach(data);
    });

    it('should provide liquidity and take ipToken - simple case 1 - 18 decimals', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, testData);
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        let liquidityAmount = testUtils.USD_14_000_18DEC;

        let expectedLiquidityProviderStableBalance = BigInt("9986000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = testUtils.USD_14_000_18DEC;

        //when
        await data.joseph.provideLiquidity(params.asset, liquidityAmount, {from: liquidityProvider})

        //then
        const actualIpTokenBalanceSender = BigInt(await data.ipTokenDai.balanceOf(liquidityProvider));
        const actualUnderlyingBalanceMilton = BigInt(await data.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await data.tokenDai.balanceOf(liquidityProvider));


        assert(liquidityAmount === actualIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${liquidityAmount}`);

        assert(liquidityAmount === actualUnderlyingBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${liquidityAmount}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect DAI balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);

    });

    it('should provide liquidity and take ipToken - simple case 1 - USDT 6 decimals', async () => {
        //given
        await testUtils.setupTokenUsdtInitialValues(data);
        await testUtils.setupIpTokenUsdtInitialValues(data, testData);
        const params = testUtils.getStandardDerivativeParamsUSDT(data);
        let liquidityAmount = testUtils.USD_14_000_6DEC;

        let expectedLiquidityProviderStableBalance = BigInt("9986000000000");
        let expectedLiquidityPoolBalanceMilton = testUtils.USD_14_000_6DEC;

        //when
        await data.joseph.provideLiquidity(params.asset, liquidityAmount, {from: liquidityProvider})

        //then
        const actualIpTokenBalanceSender = BigInt(await data.ipTokenUsdt.balanceOf(liquidityProvider));
        const actualUnderlyingBalanceMilton = BigInt(await data.tokenUsdt.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await data.tokenUsdt.balanceOf(liquidityProvider));


        assert(liquidityAmount === actualIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${liquidityAmount}`);

        assert(liquidityAmount === actualUnderlyingBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${liquidityAmount}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect USDT balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);

    });

    it('should redeem ipToken - simple case 1 - DAI 18 decimals', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, testData);
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        let liquidityAmount = testUtils.USD_14_000_18DEC;
        let withdrawAmount = testUtils.USD_10_000_18DEC;
        let expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        let expectedStableBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        await data.joseph.test_provideLiquidity(params.asset, liquidityAmount, {from: liquidityProvider})

        //when
        await data.joseph.test_redeem(params.asset, withdrawAmount, {from: liquidityProvider});

        //then
        const actualIpTokenBalanceSender = BigInt(await data.ipTokenDai.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await data.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await data.tokenDai.balanceOf(liquidityProvider));

        assert(expectedIpTokenBalanceSender === actualIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`);

        assert(expectedStableBalanceMilton === actualUnderlyingBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);

    });

    it('should redeem ipToken - simple case 1 - USDT 6 decimals', async () => {
        //given
        await testUtils.setupTokenUsdtInitialValues(data);
        await testUtils.setupIpTokenUsdtInitialValues(data, testData);
        const params = testUtils.getStandardDerivativeParamsUSDT(data);
        let liquidityAmount = testUtils.USD_14_000_6DEC;
        let withdrawAmount = testUtils.USD_10_000_6DEC;
        let expectedIpTokenBalanceSender = BigInt("4000000000");
        let expectedStableBalanceMilton = BigInt("4000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9996000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        await data.joseph.test_provideLiquidity(params.asset, liquidityAmount, {from: liquidityProvider})

        //when
        await data.joseph.test_redeem(params.asset, withdrawAmount, {from: liquidityProvider});

        //then
        const actualIpTokenBalanceSender = BigInt(await data.ipTokenUsdt.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await data.tokenUsdt.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await data.tokenUsdt.balanceOf(liquidityProvider));

        assert(expectedIpTokenBalanceSender === actualIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${params.asset} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`);

        assert(expectedStableBalanceMilton === actualUnderlyingBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect USDT balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);

    });

    it('should calculate Exchange Rate when Liquidity Pool Balance and ipToken Total Supply is zero', async () => {
        //given
        await testUtils.setupTokenDaiInitialZeroValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        let expectedExchangeRate = BigInt("1000000000000000000");

        //when
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(data.tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is NOT zero, DAI 18 decimals', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        let expectedExchangeRate = BigInt("1000000000000000000");
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        //when
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(data.tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is NOT zero, USDT 6 decimals', async () => {
        //given
        await testUtils.setupIpTokenUsdtInitialValues(data, ZERO);
        await testUtils.setupTokenUsdtInitialValues(data);

        let expectedExchangeRate = BigInt("1000000");
        const params = testUtils.getStandardDerivativeParamsUSDT(data);

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_6DEC, {from: liquidityProvider})

        //when
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(data.tokenUsdt.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for USDT, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is zero and ipToken Total Supply is NOT zero', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        let expectedExchangeRate = BigInt("0");
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_10_000_18DEC, {from: liquidityProvider})

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, testUtils.USD_10_000_18DEC, {from: userOne});
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);

        //when
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(data.tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`);

    });

    it('should calculate Exchange Rate, Exchange Rate greater than 1, DAI 18 decimals', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        let expectedExchangeRate = BigInt("1022727272727272727");
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});
        await data.joseph.provideLiquidity(params.asset, BigInt("40000000000000000000"), {from: liquidityProvider})

        //open position to have something in Liquidity Pool
        await data.milton.openPosition(
            params.asset, BigInt("40000000000000000000"),
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //when
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(data.tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });
    it('should calculate Exchange Rate, Exchange Rate greater than 1, USDT 6 decimals', async () => {
        //given
        await testUtils.setupTokenUsdtInitialValues(data);
        await testUtils.setupIpTokenUsdtInitialValues(data, ZERO);
        let expectedExchangeRate = BigInt("1022727");
        const params = testUtils.getStandardDerivativeParamsUSDT(data);
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_6DEC, {from: userOne});
        await data.joseph.provideLiquidity(params.asset, BigInt("40000000"), {from: liquidityProvider})

        //open position to have something in Liquidity Pool
        await data.milton.openPosition(
            params.asset, BigInt("40000000"),
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //when
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(data.tokenUsdt.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for USDT, actual:  ${actualExchangeRate},
                expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is zero', async () => {
        //given
        let amount = BigInt("40000000000000000000");
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        let expectedExchangeRate = BigInt("1000000000000000000");
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        await data.joseph.test_provideLiquidity(params.asset, amount, {from: liquidityProvider});


        //open position to have something in Liquidity Pool
        await data.milton.openPosition(
            params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        await data.joseph.test_redeem(params.asset, amount, {from: liquidityProvider})

        //when
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(data.tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should NOT change Exchange Rate when Liquidity Provider provide liquidity, initial Exchange Rate equal to 1.5', async () => {

        //given
        let amount = BigInt("180000000000000000000");
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});
        await data.joseph.provideLiquidity(params.asset, amount, {from: liquidityProvider});
        let oldOpeningFeePercentage = await data.iporAssetConfigurationDai.getOpeningFeePercentage();
        await data.iporAssetConfigurationDai.setOpeningFeePercentage(BigInt("600000000000000000"));

        //open position to have something in Liquidity Pool
        await data.milton.openPosition(
            params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //after this withdraw initial exchange rate is 1,5
        let expectedExchangeRate = BigInt("1714285714285714286");
        let exchangeRateBeforeProvideLiquidity = BigInt(await data.joseph.calculateExchangeRate.call(params.asset));
        let expectedIpTokenBalanceForUserThree = BigInt("874999999999999999854");

        // //when
        await data.joseph.provideLiquidity(params.asset, BigInt("1500000000000000000000"), {from: userThree});

        let actualIpTokenBalanceForUserThree = BigInt(await data.ipTokenDai.balanceOf.call(userThree));
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(params.asset));

        //then
        assert(expectedIpTokenBalanceForUserThree === actualIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
                 expected: ${expectedIpTokenBalanceForUserThree}`)

        assert(expectedExchangeRate === exchangeRateBeforeProvideLiquidity,
            `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
                expected: ${expectedExchangeRate}`)

        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
                expected: ${expectedExchangeRate}`)

        await data.iporAssetConfigurationDai.setOpeningFeePercentage(oldOpeningFeePercentage);
    });

    it('should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5, DAI 18 decimals', async () => {
        //given
        let amount = BigInt("180000000000000000000");
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});
        await data.joseph.provideLiquidity(params.asset, amount, {from: liquidityProvider});
        let oldOpeningFeePercentage = await data.iporAssetConfigurationDai.getOpeningFeePercentage();
        await data.iporAssetConfigurationDai.setOpeningFeePercentage(BigInt("600000000000000000"));

        //open position to have something in Liquidity Pool
        await data.milton.openPosition(
            params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //after this withdraw initial exchange rate is 1,5
        let expectedExchangeRate = BigInt("1714285714285714286");
        let exchangeRateBeforeProvideLiquidity = BigInt(await data.joseph.calculateExchangeRate.call(params.asset));
        let expectedIpTokenBalanceForUserThree = BigInt("0");

        //when
        await data.joseph.test_provideLiquidity(params.asset, BigInt("1500000000000000000000"), {from: userThree});
        await data.joseph.test_redeem(params.asset, BigInt("874999999999999999854"), {from: userThree})

        let actualIpTokenBalanceForUserThree = BigInt(await data.ipTokenDai.balanceOf.call(userThree));
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(params.asset));

        //then
        assert(expectedIpTokenBalanceForUserThree === actualIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for DAI asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
                 expected: ${expectedIpTokenBalanceForUserThree}`)

        assert(expectedExchangeRate === exchangeRateBeforeProvideLiquidity,
            `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
                expected: ${expectedExchangeRate}`)

        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
                expected: ${expectedExchangeRate}`)

        await data.iporAssetConfigurationDai.setOpeningFeePercentage(oldOpeningFeePercentage);
    });

    it('should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5, USDT 6 decimals', async () => {
        //given
        let amount = BigInt("180000000");
        await testUtils.setupTokenUsdtInitialValues(data);
        await testUtils.setupIpTokenUsdtInitialValues(data, ZERO);
        const params = testUtils.getStandardDerivativeParamsUSDT(data);
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_6DEC, {from: userOne});
        await data.joseph.provideLiquidity(params.asset, amount, {from: liquidityProvider});
        let oldOpeningFeePercentage = await data.iporAssetConfigurationUsdt.getOpeningFeePercentage();
        await data.iporAssetConfigurationUsdt.setOpeningFeePercentage(BigInt("600000"));

        //open position to have something in Liquidity Pool
        await data.milton.openPosition(
            params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //after this withdraw initial exchange rate is 1,5
        let expectedExchangeRate = BigInt("1714286");
        let exchangeRateBeforeProvideLiquidity = BigInt(await data.joseph.calculateExchangeRate.call(params.asset));
        let expectedIpTokenBalanceForUserThree = BigInt("0");


        //when
        await data.joseph.test_provideLiquidity(params.asset, BigInt("1500000000"), {from: userThree});
        await data.joseph.test_redeem(params.asset, BigInt("874999854"), {from: userThree})

        let actualIpTokenBalanceForUserThree = BigInt(await data.ipTokenUsdt.balanceOf.call(userThree));
        let actualExchangeRate = BigInt(await data.joseph.calculateExchangeRate.call(params.asset));

        //then
        assert(expectedIpTokenBalanceForUserThree === actualIpTokenBalanceForUserThree,
            `Incorrect ipToken Balance for USDT asset ${params.asset} for user ${userThree}, actual:  ${actualIpTokenBalanceForUserThree},
                 expected: ${expectedIpTokenBalanceForUserThree}`)

        assert(expectedExchangeRate === exchangeRateBeforeProvideLiquidity,
            `Incorrect exchange rate before providing liquidity for USDT, actual:  ${exchangeRateBeforeProvideLiquidity},
                expected: ${expectedExchangeRate}`)

        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate after providing liquidity for USDT, actual:  ${actualExchangeRate},
                expected: ${expectedExchangeRate}`)

        await data.iporAssetConfigurationDai.setOpeningFeePercentage(oldOpeningFeePercentage);
    });


    it('should NOT redeem ipTokens because of empty Liquidity Pool', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenUsdtInitialValues(data, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        await data.joseph.test_provideLiquidity(params.asset, params.totalAmount, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, params.totalAmount, {from: userOne});
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);

        //when
        await testUtils.assertError(
            //when
            data.joseph.test_redeem(params.asset, BigInt("1000000000000000000000"), {from: liquidityProvider}),
            //then
            'IPOR_45'
        );
    });

    it('should NOT provide liquidity because of empty Liquidity Pool', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        await data.joseph.provideLiquidity(params.asset, params.totalAmount, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, params.totalAmount, {from: userOne});
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);

        //when
        await testUtils.assertError(
            //when
            data.joseph.provideLiquidity(params.asset, params.totalAmount, {from: liquidityProvider}),
            //then
            'IPOR_45'
        );
    });

    it('should NOT redeem ipTokens because redeem value higher than Liquidity Pool Balance', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        await data.joseph.test_provideLiquidity(params.asset, params.totalAmount, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, testUtils.USD_10_18DEC, {from: userOne});
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);

        //when
        await testUtils.assertError(
            //when
            data.joseph.test_redeem(params.asset, params.totalAmount, {from: liquidityProvider}),
            //then
            'IPOR_43'
        );
    });

    it('should NOT redeem ipTokens because after redeem Liquidity Pool will be empty', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.joseph.test_provideLiquidity(params.asset, params.totalAmount, {from: liquidityProvider});

        //when
        await testUtils.assertError(
            //when
            data.joseph.test_redeem(params.asset, params.totalAmount, {from: liquidityProvider}),
            //then
            'IPOR_43'
        );
    });

    it('should redeem ipTokens because NO validation for cool off period', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        let liquidityAmount = testUtils.USD_14_000_18DEC;
        let withdrawAmount = testUtils.USD_10_000_18DEC;
        await data.joseph.test_provideLiquidity(data.tokenDai.address, liquidityAmount, {from: liquidityProvider});

        //when
        await data.joseph.test_redeem(data.tokenDai.address, withdrawAmount, {from: liquidityProvider});


        let expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        let expectedStableBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        //then
        const actualIpTokenBalanceSender = BigInt(await data.ipTokenDai.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await data.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(data.tokenDai.address)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await data.tokenDai.balanceOf(liquidityProvider));

        assert(expectedIpTokenBalanceSender === actualIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${data.tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`);

        assert(expectedStableBalanceMilton === actualUnderlyingBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${data.tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${data.tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${data.tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);

    });

    it('should redeem ipTokens, two times provided liquidity', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);

        await data.joseph.test_provideLiquidity(data.tokenDai.address, testUtils.USD_10_000_18DEC, {from: liquidityProvider});
        await data.joseph.test_provideLiquidity(data.tokenDai.address, testUtils.USD_10_000_18DEC, {from: liquidityProvider});

        //when
        await data.joseph.test_redeem(data.tokenDai.address, testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        //then
        let expectedIpTokenBalanceSender = BigInt("6000000000000000000000");
        let expectedStableBalanceMilton = BigInt("6000000000000000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9994000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        const actualIpTokenBalanceSender = BigInt(await data.ipTokenDai.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await data.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(data.tokenDai.address)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await data.tokenDai.balanceOf(liquidityProvider));

        assert(expectedIpTokenBalanceSender === actualIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${data.tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`);

        assert(expectedStableBalanceMilton === actualUnderlyingBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${data.tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${data.tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${data.tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);
    });

    it('should redeem ipDAI, should redeem ipUSDT - simple case 1', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupTokenUsdtInitialValues(data);

        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        await testUtils.setupIpTokenUsdtInitialValues(data, ZERO);

        let liquidityAmountDAI = testUtils.USD_14_000_18DEC;
        let withdrawAmountDAI = testUtils.USD_10_000_18DEC;

        let liquidityAmountUSDT = testUtils.USD_14_000_6DEC;
        let withdrawAmountUSDT = testUtils.USD_10_000_6DEC;

        let expectedipDAIBalanceSender = BigInt("4000000000000000000000");
        let expectedDAIBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderDAIBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        let expectedipUSDTBalanceSender = BigInt("4000000000");
        let expectedUSDTBalanceMilton = BigInt("4000000000");
        let expectedLiquidityProviderUSDTBalance = BigInt("9996000000000");
        let expectedLiquidityPoolUSDTBalanceMilton = expectedUSDTBalanceMilton;

        await data.joseph.test_provideLiquidity(data.tokenDai.address, liquidityAmountDAI, {from: liquidityProvider});
        await data.joseph.test_provideLiquidity(data.tokenUsdt.address, liquidityAmountUSDT, {from: liquidityProvider});

        //when
        await data.joseph.test_redeem(data.tokenDai.address, withdrawAmountDAI, {from: liquidityProvider});
        await data.joseph.test_redeem(data.tokenUsdt.address, withdrawAmountUSDT, {from: liquidityProvider});

        //then
        const actualIpDAIBalanceSender = BigInt(await data.ipTokenDai.balanceOf(liquidityProvider));
        const actualDAIBalanceMilton = BigInt(await data.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolDAIBalanceMilton = BigInt(await (await testData.miltonStorage.balances(data.tokenDai.address)).liquidityPool);
        const actualDAIBalanceSender = BigInt(await data.tokenDai.balanceOf(liquidityProvider));

        assert(expectedipDAIBalanceSender === actualIpDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${data.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`);

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${data.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);

        assert(expectedLiquidityPoolDAIBalanceMilton === actualLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${data.tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`);

        assert(expectedLiquidityProviderDAIBalance === actualDAIBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${data.tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`);

        const actualIpUSDTBalanceSender = BigInt(await data.ipTokenUsdt.balanceOf(liquidityProvider));
        const actualUSDTBalanceMilton = BigInt(await data.tokenUsdt.balanceOf(data.milton.address));

        const actualLiquidityPoolUSDTBalanceMilton = BigInt(await (await testData.miltonStorage.balances(data.tokenUsdt.address)).liquidityPool);
        const actualUSDTBalanceSender = BigInt(await data.tokenUsdt.balanceOf(liquidityProvider));

        assert(expectedipUSDTBalanceSender === actualIpUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${data.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedipUSDTBalanceSender}`);

        assert(expectedUSDTBalanceMilton === actualUSDTBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${data.tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`);

        assert(expectedLiquidityPoolUSDTBalanceMilton === actualLiquidityPoolUSDTBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${data.tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`);

        assert(expectedLiquidityProviderUSDTBalance === actualUSDTBalanceSender,
            `Incorrect USDT balance on Liquidity Provider for asset ${data.tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`);
    });

    it('should redeem ipDAI, should redeem ipUSDT, two users - simple case 1', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupTokenUsdtInitialValues(data);

        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);
        await testUtils.setupIpTokenUsdtInitialValues(data, ZERO);

        let liquidityAmountDAI = testUtils.USD_14_000_18DEC;
        let withdrawAmountDAI = testUtils.USD_10_000_18DEC;
        let liquidityAmountUSDT = testUtils.USD_14_000_6DEC;
        let withdrawAmountUSDT = testUtils.USD_10_000_6DEC;

        let expectedipDAIBalanceSender = BigInt("4000000000000000000000");
        let expectedDAIBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderDAIBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        let expectedipUSDTBalanceSender = BigInt("4000000000");
        let expectedUSDTBalanceMilton = BigInt("4000000000");
        let expectedLiquidityProviderUSDTBalance = BigInt("9996000000000");
        let expectedLiquidityPoolUSDTBalanceMilton = expectedUSDTBalanceMilton;

        let daiUser = userOne;
        let usdtUser = userTwo;
        await data.joseph.test_provideLiquidity(data.tokenDai.address, liquidityAmountDAI, {from: daiUser});
        await data.joseph.test_provideLiquidity(data.tokenUsdt.address, liquidityAmountUSDT, {from: usdtUser});

        //when
        await data.joseph.test_redeem(data.tokenDai.address, withdrawAmountDAI, {from: daiUser});
        await data.joseph.test_redeem(data.tokenUsdt.address, withdrawAmountUSDT, {from: usdtUser});

        //then
        const actualIpDAIBalanceSender = BigInt(await data.ipTokenDai.balanceOf(daiUser));
        const actualDAIBalanceMilton = BigInt(await data.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolDAIBalanceMilton = BigInt(await (await testData.miltonStorage.balances(data.tokenDai.address)).liquidityPool);
        const actualDAIBalanceSender = BigInt(await data.tokenDai.balanceOf(daiUser));

        assert(expectedipDAIBalanceSender === actualIpDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${data.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`);

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${data.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);

        assert(expectedLiquidityPoolDAIBalanceMilton === actualLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${data.tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`);

        assert(expectedLiquidityProviderDAIBalance === actualDAIBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${data.tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`);

        const actualIpUSDTBalanceSender = BigInt(await data.ipTokenUsdt.balanceOf(usdtUser));
        const actualUSDTBalanceMilton = BigInt(await data.tokenUsdt.balanceOf(data.milton.address));

        const actualLiquidityPoolUSDTBalanceMilton = BigInt(await (await testData.miltonStorage.balances(data.tokenUsdt.address)).liquidityPool);
        const actualUSDTBalanceSender = BigInt(await data.tokenUsdt.balanceOf(usdtUser));

        assert(expectedipUSDTBalanceSender === actualIpUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${data.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedipUSDTBalanceSender}`);

        assert(expectedUSDTBalanceMilton === actualUSDTBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${data.tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`);

        assert(expectedLiquidityPoolUSDTBalanceMilton === actualLiquidityPoolUSDTBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${data.tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`);

        assert(expectedLiquidityProviderUSDTBalance === actualUSDTBalanceSender,
            `Incorrect USDT balance on Liquidity Provider for asset ${data.tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`);
    });

    it('should redeem - Liquidity Provider can transfer tokens to other user, user can redeem tokens', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupIpTokenDaiInitialValues(data, ZERO);

        await data.joseph.test_provideLiquidity(data.tokenDai.address, testUtils.USD_10_400_18DEC, {from: liquidityProvider});

        await data.ipTokenDai.transfer(userThree, testUtils.USD_10_000_18DEC, {from: liquidityProvider});

        await data.joseph.test_redeem(data.tokenDai.address, testUtils.USD_10_000_18DEC, {from: userThree});

        let expectedDAIBalanceMilton = BigInt("400000000000000000000");
        let expectedDAIBalanceMiltonLiquidityPool = expectedDAIBalanceMilton;

        let expectedIpDAIBalanceLiquidityProvider = BigInt("400000000000000000000");
        let expectedDAIBalanceLiquidityProvider = BigInt("9989600000000000000000000");

        let expectedIpDAIBalanceUserThree = BigInt("0");
        let expectedDAIBalanceUserThree = BigInt("10010000000000000000000000");

        const actualDAIBalanceMilton = BigInt(await data.tokenDai.balanceOf(data.milton.address));
        const actualDAIBalanceMiltonLiquidityPool = BigInt(await (await testData.miltonStorage.balances(data.tokenDai.address)).liquidityPool);

        const actualIpDAIBalanceLiquidityProvider = BigInt(await data.ipTokenDai.balanceOf(liquidityProvider));
        const actualDAIBalanceLiquidityProvider = BigInt(await data.tokenDai.balanceOf(liquidityProvider));

        const actualIpDAIBalanceUserThree = BigInt(await data.ipTokenDai.balanceOf(userThree));
        const actualDAIBalanceUserThree = BigInt(await data.tokenDai.balanceOf(userThree));

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${data.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);
        assert(expectedDAIBalanceMiltonLiquidityPool === actualDAIBalanceMiltonLiquidityPool,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${data.tokenDai.address} actual: ${actualDAIBalanceMiltonLiquidityPool}, expected: ${expectedDAIBalanceMiltonLiquidityPool}`);

        assert(expectedIpDAIBalanceLiquidityProvider === actualIpDAIBalanceLiquidityProvider,
            `Incorrect ipToken DAI balance on Liquidity Provider for asset ${data.tokenDai.address} actual: ${actualIpDAIBalanceLiquidityProvider}, expected: ${expectedIpDAIBalanceLiquidityProvider}`);
        assert(expectedDAIBalanceLiquidityProvider === actualDAIBalanceLiquidityProvider,
            `Incorrect DAI balance on Liquidity Provider for asset ${data.tokenDai.address} actual: ${actualDAIBalanceLiquidityProvider}, expected: ${expectedDAIBalanceLiquidityProvider}`);

        assert(expectedIpDAIBalanceUserThree === actualIpDAIBalanceUserThree,
            `Incorrect ipToken DAI balance on user for asset ${data.tokenDai.address} actual: ${actualIpDAIBalanceUserThree}, expected: ${expectedIpDAIBalanceUserThree}`);
        assert(expectedDAIBalanceUserThree === actualDAIBalanceUserThree,
            `Incorrect DAI balance on user for asset ${data.tokenDai.address} actual: ${actualDAIBalanceUserThree}, expected: ${expectedDAIBalanceUserThree}`);

    });
    //TODO: add tests for pausable methods
});
