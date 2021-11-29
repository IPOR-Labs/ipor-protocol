const keccak256 = require("keccak256");
const testUtils = require("./TestUtils.js");
const {ZERO} = require("./TestUtils");

contract('Joseph', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, userFive, _] = accounts;

    let data = null;

    before(async () => {
        data = await testUtils.prepareData(admin);
    });

    it('should provide liquidity and take ipToken - simple case 1 - 18 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);
        let liquidityAmount = testUtils.USD_14_000_18DEC;

        let expectedLiquidityProviderStableBalance = BigInt("9986000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = testUtils.USD_14_000_18DEC;

        //when
        await data.joseph.test_provideLiquidity(params.asset, liquidityAmount, params.openTimestamp, {from: liquidityProvider})

        //then
        const actualIpTokenBalanceSender = BigInt(await testData.ipTokenDai.balanceOf(liquidityProvider));
        const actualUnderlyingBalanceMilton = BigInt(await testData.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await testData.tokenDai.balanceOf(liquidityProvider));


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
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["USDT"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "USDT", data, testData);
        await testUtils.setupTokenUsdtInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsUSDT(userTwo, testData);
        let liquidityAmount = testUtils.USD_14_000_6DEC;

        let expectedLiquidityProviderStableBalance = BigInt("9986000000000");
        let expectedLiquidityPoolBalanceMilton = testUtils.USD_14_000_6DEC;

        //when
        await data.joseph.test_provideLiquidity(params.asset, liquidityAmount, params.openTimestamp, {from: liquidityProvider})

        //then
        const actualIpTokenBalanceSender = BigInt(await testData.ipTokenUsdt.balanceOf(liquidityProvider));
        const actualUnderlyingBalanceMilton = BigInt(await testData.tokenUsdt.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await testData.tokenUsdt.balanceOf(liquidityProvider));


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
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        let liquidityAmount = testUtils.USD_14_000_18DEC;
        let withdrawAmount = testUtils.USD_10_000_18DEC;
        let expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        let expectedStableBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        await data.joseph.test_provideLiquidity(params.asset, liquidityAmount, params.openTimestamp, {from: liquidityProvider})

        //when
        await data.joseph.test_redeem(params.asset, withdrawAmount, params.openTimestamp, {from: liquidityProvider});

        //then
        const actualIpTokenBalanceSender = BigInt(await testData.ipTokenDai.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await testData.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await testData.tokenDai.balanceOf(liquidityProvider));

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
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["USDT"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "USDT", data, testData);
        await testUtils.setupTokenUsdtInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsUSDT(userTwo, testData);
        let liquidityAmount = testUtils.USD_14_000_6DEC;
        let withdrawAmount = testUtils.USD_10_000_6DEC;
        let expectedIpTokenBalanceSender = BigInt("4000000000");
        let expectedStableBalanceMilton = BigInt("4000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9996000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        await data.joseph.test_provideLiquidity(params.asset, liquidityAmount, params.openTimestamp, {from: liquidityProvider})

        //when
        await data.joseph.test_redeem(params.asset, withdrawAmount, params.openTimestamp, {from: liquidityProvider});

        //then
        const actualIpTokenBalanceSender = BigInt(await testData.ipTokenUsdt.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await testData.tokenUsdt.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await testData.tokenUsdt.balanceOf(liquidityProvider));

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
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);

        let expectedExchangeRate = BigInt("1000000000000000000");

        //when
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(testData.tokenDai.address, Math.floor(Date.now() / 1000)));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is NOT zero, DAI 18 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        let expectedExchangeRate = BigInt("1000000000000000000");

        await data.joseph.test_provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, params.openTimestamp, {from: liquidityProvider})

        //when
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(testData.tokenDai.address, params.openTimestamp));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is NOT zero, USDT 6 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["USDT"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "USDT", data, testData);
        await testUtils.setupTokenUsdtInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsUSDT(userTwo, testData);

        let expectedExchangeRate = BigInt("1000000");

        await data.joseph.test_provideLiquidity(params.asset, testUtils.USD_14_000_6DEC, params.openTimestamp, {from: liquidityProvider})

        //when
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(testData.tokenUsdt.address, params.openTimestamp));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for USDT, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is zero and ipToken Total Supply is NOT zero', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        let expectedExchangeRate = BigInt("0");

        await data.joseph.test_provideLiquidity(params.asset, testUtils.USD_10_000_18DEC, params.openTimestamp, {from: liquidityProvider})

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await data.iporConfiguration.setJoseph(userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, testUtils.USD_10_000_18DEC, {from: userOne});
        await data.iporConfiguration.setJoseph(data.joseph.address);

        //when
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(testData.tokenDai.address, params.openTimestamp));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`);

    });

    it('should calculate Exchange Rate, Exchange Rate greater than 1, DAI 18 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        let expectedExchangeRate = BigInt("1022727272727272727");

        await data.warren.test_updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, params.openTimestamp, {from: userOne});
        await data.joseph.test_provideLiquidity(params.asset, BigInt("40000000000000000000"), params.openTimestamp, {from: liquidityProvider})

        //open position to have something in Liquidity Pool
        await data.milton.test_openPosition(
            params.openTimestamp, params.asset, BigInt("40000000000000000000"),
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //when
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(testData.tokenDai.address, params.openTimestamp));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    //
    // it('should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance', async () => {
    //     //TODO: add this test
    // });
    //
    // it('should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance', async () => {
    //     //TODO: add this test
    // });
    //
    // it('should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance', async () => {
    //     //TODO: add this test
    // });
    //
    // it('should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance', async () => {
    //     //TODO: add this test
    // });

    it('should calculate Exchange Rate, Exchange Rate greater than 1, USDT 6 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["USDT"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "USDT", data, testData);
        await testUtils.setupTokenUsdtInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsUSDT(userTwo, testData);

        let expectedExchangeRate = BigInt("1022727");

        await data.warren.test_updateIndex(params.asset, testUtils.PERCENTAGE_3_6DEC, params.openTimestamp, {from: userOne});
        await data.joseph.test_provideLiquidity(params.asset, BigInt("40000000"), params.openTimestamp, {from: liquidityProvider})

        //open position to have something in Liquidity Pool
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset, BigInt("40000000"),
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //when
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(testData.tokenUsdt.address, params.openTimestamp));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for USDT, actual:  ${actualExchangeRate},
                expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and ipToken Total Supply is zero', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        let amount = BigInt("40000000000000000000");
        let expectedExchangeRate = BigInt("1000000000000000000");

        await data.warren.test_updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, params.openTimestamp, {from: userOne});

        await data.joseph.test_provideLiquidity(params.asset, amount, params.openTimestamp, {from: liquidityProvider});


        //open position to have something in Liquidity Pool
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        await data.joseph.test_redeem(params.asset, amount, params.openTimestamp, {from: liquidityProvider})

        //when
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(testData.tokenDai.address, params.openTimestamp));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should NOT change Exchange Rate when Liquidity Provider provide liquidity, initial Exchange Rate equal to 1.5', async () => {

        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testData.iporAssetConfigurationDai.grantRole(keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"), admin);
        await testData.iporAssetConfigurationDai.grantRole(keccak256("OPENING_FEE_PERCENTAGE_ROLE"), admin);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        let amount = BigInt("180000000000000000000");
        await data.warren.test_updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, params.openTimestamp, {from: userOne});
        await data.joseph.test_provideLiquidity(params.asset, amount, params.openTimestamp, {from: liquidityProvider});
        let oldOpeningFeePercentage = await testData.iporAssetConfigurationDai.getOpeningFeePercentage();
        await testData.iporAssetConfigurationDai.setOpeningFeePercentage(BigInt("600000000000000000"));

        //open position to have something in Liquidity Pool
        await data.milton.test_openPosition(
            params.openTimestamp, params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction,  {from: userTwo});

        //after this withdraw initial exchange rate is 1,5
        let expectedExchangeRate = BigInt("1714285714285714286");
        let exchangeRateBeforeProvideLiquidity = BigInt(await data.milton.calculateExchangeRate.call(params.asset, params.openTimestamp));
        let expectedIpTokenBalanceForUserThree = BigInt("874999999999999999854");

        // //when
        await data.joseph.test_provideLiquidity(params.asset, BigInt("1500000000000000000000"), params.openTimestamp, {from: userThree});

        let actualIpTokenBalanceForUserThree = BigInt(await testData.ipTokenDai.balanceOf.call(userThree));
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(params.asset, params.openTimestamp));

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

        await testData.iporAssetConfigurationDai.setOpeningFeePercentage(oldOpeningFeePercentage);
    });

    it('should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5, DAI 18 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        let amount = BigInt("180000000000000000000");

        await data.warren.test_updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, params.openTimestamp, {from: userOne});
        await data.joseph.test_provideLiquidity(params.asset, amount, params.openTimestamp, {from: liquidityProvider});
        let oldOpeningFeePercentage = await testData.iporAssetConfigurationDai.getOpeningFeePercentage();
        await testData.iporAssetConfigurationDai.grantRole(keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"), admin);
        await testData.iporAssetConfigurationDai.grantRole(keccak256("OPENING_FEE_PERCENTAGE_ROLE"), admin);
        await testData.iporAssetConfigurationDai.setOpeningFeePercentage(BigInt("600000000000000000"));

        //open position to have something in Liquidity Pool
        await data.milton.test_openPosition(
            params.openTimestamp, params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //after this withdraw initial exchange rate is 1,5
        let expectedExchangeRate = BigInt("1714285714285714286");
        let exchangeRateBeforeProvideLiquidity = BigInt(await data.milton.calculateExchangeRate.call(params.asset, params.openTimestamp));
        let expectedIpTokenBalanceForUserThree = BigInt("0");

        //when
        await data.joseph.test_provideLiquidity(params.asset, BigInt("1500000000000000000000"), params.openTimestamp, {from: userThree});
        await data.joseph.test_redeem(params.asset, BigInt("874999999999999999854"), params.openTimestamp,  {from: userThree})

        let actualIpTokenBalanceForUserThree = BigInt(await testData.ipTokenDai.balanceOf.call(userThree));
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(params.asset, params.openTimestamp));

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

        await testData.iporAssetConfigurationDai.setOpeningFeePercentage(oldOpeningFeePercentage);
    });

    it('should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5, USDT 6 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["USDT"], data);
        await testData.iporAssetConfigurationUsdt.grantRole(keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"), admin);
        await testData.iporAssetConfigurationUsdt.grantRole(keccak256("OPENING_FEE_PERCENTAGE_ROLE"), admin);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "USDT", data, testData);
        await testUtils.setupTokenUsdtInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsUSDT(userTwo, testData);
        
        let amount = BigInt("180000000");        
        await data.warren.test_updateIndex(params.asset, testUtils.PERCENTAGE_3_6DEC, params.openTimestamp, {from: userOne});
        await data.joseph.test_provideLiquidity(params.asset, amount, params.openTimestamp, {from: liquidityProvider});
        let oldOpeningFeePercentage = await testData.iporAssetConfigurationUsdt.getOpeningFeePercentage();
        await testData.iporAssetConfigurationUsdt.setOpeningFeePercentage(BigInt("600000"));

        //open position to have something in Liquidity Pool
        await data.milton.test_openPosition(
            params.openTimestamp, params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //after this withdraw initial exchange rate is 1,5
        let expectedExchangeRate = BigInt("1714286");
        let exchangeRateBeforeProvideLiquidity = BigInt(await data.milton.calculateExchangeRate.call(params.asset, params.openTimestamp));
        let expectedIpTokenBalanceForUserThree = BigInt("0");


        //when
        await data.joseph.test_provideLiquidity(params.asset, BigInt("1500000000"), params.openTimestamp, {from: userThree});
        await data.joseph.test_redeem(params.asset, BigInt("874999854"), params.openTimestamp, {from: userThree})

        let actualIpTokenBalanceForUserThree = BigInt(await testData.ipTokenUsdt.balanceOf.call(userThree));
        let actualExchangeRate = BigInt(await data.milton.calculateExchangeRate.call(params.asset, params.openTimestamp));

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

        await testData.iporAssetConfigurationUsdt.setOpeningFeePercentage(oldOpeningFeePercentage);
    });



    it('should NOT redeem ipTokens because of empty Liquidity Pool', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        await data.joseph.test_provideLiquidity(params.asset, params.totalAmount, params.openTimestamp, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await data.iporConfiguration.setJoseph(userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, params.totalAmount, {from: userOne});
        await data.iporConfiguration.setJoseph(data.joseph.address);

        //when
        await testUtils.assertError(
            //when
            data.joseph.test_redeem(params.asset, BigInt("1000000000000000000000"), params.openTimestamp, {from: liquidityProvider}),
            //then
            'IPOR_45'
        );
    });

    it('should NOT provide liquidity because of empty Liquidity Pool', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        await data.joseph.test_provideLiquidity(params.asset, params.totalAmount, params.openTimestamp, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await data.iporConfiguration.setJoseph(userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, params.totalAmount, {from: userOne});
        await data.iporConfiguration.setJoseph(data.joseph.address);

        //when
        await testUtils.assertError(
            //when
            data.joseph.test_provideLiquidity(params.asset, params.totalAmount, params.openTimestamp, {from: liquidityProvider}),
            //then
            'IPOR_45'
        );
    });

    it('should NOT redeem ipTokens because redeem value higher than Liquidity Pool Balance', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        await data.joseph.test_provideLiquidity(params.asset, params.totalAmount, params.openTimestamp, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await data.iporConfiguration.setJoseph(userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, testUtils.USD_10_18DEC, {from: userOne});
        await data.iporConfiguration.setJoseph(data.joseph.address);

        //when
        await testUtils.assertError(
            //when
            data.joseph.test_redeem(params.asset, params.totalAmount, params.openTimestamp, {from: liquidityProvider}),
            //then
            'IPOR_43'
        );
    });

    it('should NOT redeem ipTokens because after redeem Liquidity Pool will be empty', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        const params = testUtils.getStandardDerivativeParamsDAI(userTwo, testData);

        await data.joseph.test_provideLiquidity(params.asset, params.totalAmount, params.openTimestamp, {from: liquidityProvider});

        //when
        await testUtils.assertError(
            //when
            data.joseph.test_redeem(params.asset, params.totalAmount, params.openTimestamp, {from: liquidityProvider}),
            //then
            'IPOR_43'
        );
    });

    it('should redeem ipTokens because NO validation for cool off period', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);

        let liquidityAmount = testUtils.USD_14_000_18DEC;
        let withdrawAmount = testUtils.USD_10_000_18DEC;

        let timestamp = Math.floor(Date.now() / 1000);

        await data.joseph.test_provideLiquidity(testData.tokenDai.address, liquidityAmount, timestamp, {from: liquidityProvider});

        //when
        await data.joseph.test_redeem(testData.tokenDai.address, withdrawAmount, timestamp, {from: liquidityProvider});


        let expectedIpTokenBalanceSender = BigInt("4000000000000000000000");
        let expectedStableBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        //then
        const actualIpTokenBalanceSender = BigInt(await testData.ipTokenDai.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await testData.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(testData.tokenDai.address)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await testData.tokenDai.balanceOf(liquidityProvider));

        assert(expectedIpTokenBalanceSender === actualIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${testData.tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`);

        assert(expectedStableBalanceMilton === actualUnderlyingBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);

    });

    it('should redeem ipTokens, two times provided liquidity', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        let timestamp = Math.floor(Date.now() / 1000);
        await data.joseph.test_provideLiquidity(testData.tokenDai.address, testUtils.USD_10_000_18DEC, timestamp, {from: liquidityProvider});
        await data.joseph.test_provideLiquidity(testData.tokenDai.address, testUtils.USD_10_000_18DEC, timestamp, {from: liquidityProvider});

        //when
        await data.joseph.test_redeem(testData.tokenDai.address, testUtils.USD_14_000_18DEC, timestamp, {from: liquidityProvider})

        //then
        let expectedIpTokenBalanceSender = BigInt("6000000000000000000000");
        let expectedStableBalanceMilton = BigInt("6000000000000000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9994000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;

        const actualIpTokenBalanceSender = BigInt(await testData.ipTokenDai.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await testData.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await testData.miltonStorage.balances(testData.tokenDai.address)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await testData.tokenDai.balanceOf(liquidityProvider));

        assert(expectedIpTokenBalanceSender === actualIpTokenBalanceSender,
            `Incorrect ipToken balance on user for asset ${testData.tokenDai.address} actual: ${actualIpTokenBalanceSender}, expected: ${expectedIpTokenBalanceSender}`);

        assert(expectedStableBalanceMilton === actualUnderlyingBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);
    });

    it('should redeem ipDAI, should redeem ipUSDT - simple case 1', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI", "USDT"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "USDT", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupTokenUsdtInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        await testUtils.setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);

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

        let timestamp = Math.floor(Date.now() / 1000);

        await data.joseph.test_provideLiquidity(testData.tokenDai.address, liquidityAmountDAI, timestamp, {from: liquidityProvider});
        await data.joseph.test_provideLiquidity(testData.tokenUsdt.address, liquidityAmountUSDT, timestamp, {from: liquidityProvider});

        //when
        await data.joseph.test_redeem(testData.tokenDai.address, withdrawAmountDAI, timestamp, {from: liquidityProvider});
        await data.joseph.test_redeem(testData.tokenUsdt.address, withdrawAmountUSDT, timestamp, {from: liquidityProvider});

        //then
        const actualIpDAIBalanceSender = BigInt(await testData.ipTokenDai.balanceOf(liquidityProvider));
        const actualDAIBalanceMilton = BigInt(await testData.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolDAIBalanceMilton = BigInt(await (await testData.miltonStorage.balances(testData.tokenDai.address)).liquidityPool);
        const actualDAIBalanceSender = BigInt(await testData.tokenDai.balanceOf(liquidityProvider));

        assert(expectedipDAIBalanceSender === actualIpDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`);

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);

        assert(expectedLiquidityPoolDAIBalanceMilton === actualLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`);

        assert(expectedLiquidityProviderDAIBalance === actualDAIBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`);

        const actualIpUSDTBalanceSender = BigInt(await testData.ipTokenUsdt.balanceOf(liquidityProvider));
        const actualUSDTBalanceMilton = BigInt(await testData.tokenUsdt.balanceOf(data.milton.address));

        const actualLiquidityPoolUSDTBalanceMilton = BigInt(await (await testData.miltonStorage.balances(testData.tokenUsdt.address)).liquidityPool);
        const actualUSDTBalanceSender = BigInt(await testData.tokenUsdt.balanceOf(liquidityProvider));

        assert(expectedipUSDTBalanceSender === actualIpUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${testData.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedipUSDTBalanceSender}`);

        assert(expectedUSDTBalanceMilton === actualUSDTBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`);

        assert(expectedLiquidityPoolUSDTBalanceMilton === actualLiquidityPoolUSDTBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`);

        assert(expectedLiquidityProviderUSDTBalance === actualUSDTBalanceSender,
            `Incorrect USDT balance on Liquidity Provider for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`);
    });

    it('should redeem ipDAI, should redeem ipUSDT, two users - simple case 1', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI", "USDT"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "USDT", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupTokenUsdtInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        await testUtils.setupIpTokenUsdtInitialValues(liquidityProvider, ZERO);

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

        let timestamp = Math.floor(Date.now() / 1000);

        await data.joseph.test_provideLiquidity(testData.tokenDai.address, liquidityAmountDAI, timestamp, {from: daiUser});
        await data.joseph.test_provideLiquidity(testData.tokenUsdt.address, liquidityAmountUSDT, timestamp, {from: usdtUser});

        //when
        await data.joseph.test_redeem(testData.tokenDai.address, withdrawAmountDAI, timestamp, {from: daiUser});
        await data.joseph.test_redeem(testData.tokenUsdt.address, withdrawAmountUSDT, timestamp, {from: usdtUser});

        //then
        const actualIpDAIBalanceSender = BigInt(await testData.ipTokenDai.balanceOf(daiUser));
        const actualDAIBalanceMilton = BigInt(await testData.tokenDai.balanceOf(data.milton.address));
        const actualLiquidityPoolDAIBalanceMilton = BigInt(await (await testData.miltonStorage.balances(testData.tokenDai.address)).liquidityPool);
        const actualDAIBalanceSender = BigInt(await testData.tokenDai.balanceOf(daiUser));

        assert(expectedipDAIBalanceSender === actualIpDAIBalanceSender,
            `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`);

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);

        assert(expectedLiquidityPoolDAIBalanceMilton === actualLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`);

        assert(expectedLiquidityProviderDAIBalance === actualDAIBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`);

        const actualIpUSDTBalanceSender = BigInt(await testData.ipTokenUsdt.balanceOf(usdtUser));
        const actualUSDTBalanceMilton = BigInt(await testData.tokenUsdt.balanceOf(data.milton.address));

        const actualLiquidityPoolUSDTBalanceMilton = BigInt(await (await testData.miltonStorage.balances(testData.tokenUsdt.address)).liquidityPool);
        const actualUSDTBalanceSender = BigInt(await testData.tokenUsdt.balanceOf(usdtUser));

        assert(expectedipUSDTBalanceSender === actualIpUSDTBalanceSender,
            `Incorrect ipToken USDT balance on user for asset ${testData.tokenUsdt.address} actual: ${actualIpUSDTBalanceSender}, expected: ${expectedipUSDTBalanceSender}`);

        assert(expectedUSDTBalanceMilton === actualUSDTBalanceMilton,
            `Incorrect USDT balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceMilton}, expected: ${expectedUSDTBalanceMilton}`);

        assert(expectedLiquidityPoolUSDTBalanceMilton === actualLiquidityPoolUSDTBalanceMilton,
            `Incorrect USDT Liquidity Pool Balance on Milton for asset ${testData.tokenUsdt.address} actual: ${actualLiquidityPoolUSDTBalanceMilton}, expected: ${expectedLiquidityPoolUSDTBalanceMilton}`);

        assert(expectedLiquidityProviderUSDTBalance === actualUSDTBalanceSender,
            `Incorrect USDT balance on Liquidity Provider for asset ${testData.tokenUsdt.address} actual: ${actualUSDTBalanceSender}, expected: ${expectedLiquidityProviderUSDTBalance}`);
    });

    it('should redeem - Liquidity Provider can transfer tokens to other user, user can redeem tokens', async () => {
        //given
        let testData = await testUtils.prepareTestData([admin, userOne, userTwo, userThree, liquidityProvider], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, userThree, liquidityProvider], testData);
        await testUtils.setupIpTokenDaiInitialValues(liquidityProvider, ZERO);
        let timestamp = Math.floor(Date.now() / 1000);
        await data.joseph.test_provideLiquidity(testData.tokenDai.address, testUtils.USD_10_400_18DEC, timestamp, {from: liquidityProvider});

        await testData.ipTokenDai.transfer(userThree, testUtils.USD_10_000_18DEC, {from: liquidityProvider});

        await data.joseph.test_redeem(testData.tokenDai.address, testUtils.USD_10_000_18DEC, timestamp, {from: userThree});

        let expectedDAIBalanceMilton = BigInt("400000000000000000000");
        let expectedDAIBalanceMiltonLiquidityPool = expectedDAIBalanceMilton;

        let expectedIpDAIBalanceLiquidityProvider = BigInt("400000000000000000000");
        let expectedDAIBalanceLiquidityProvider = BigInt("9989600000000000000000000");

        let expectedIpDAIBalanceUserThree = BigInt("0");
        let expectedDAIBalanceUserThree = BigInt("10010000000000000000000000");

        const actualDAIBalanceMilton = BigInt(await testData.tokenDai.balanceOf(data.milton.address));
        const actualDAIBalanceMiltonLiquidityPool = BigInt(await (await testData.miltonStorage.balances(testData.tokenDai.address)).liquidityPool);

        const actualIpDAIBalanceLiquidityProvider = BigInt(await testData.ipTokenDai.balanceOf(liquidityProvider));
        const actualDAIBalanceLiquidityProvider = BigInt(await testData.tokenDai.balanceOf(liquidityProvider));

        const actualIpDAIBalanceUserThree = BigInt(await testData.ipTokenDai.balanceOf(userThree));
        const actualDAIBalanceUserThree = BigInt(await testData.tokenDai.balanceOf(userThree));

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);
        assert(expectedDAIBalanceMiltonLiquidityPool === actualDAIBalanceMiltonLiquidityPool,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceMiltonLiquidityPool}, expected: ${expectedDAIBalanceMiltonLiquidityPool}`);

        assert(expectedIpDAIBalanceLiquidityProvider === actualIpDAIBalanceLiquidityProvider,
            `Incorrect ipToken DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceLiquidityProvider}, expected: ${expectedIpDAIBalanceLiquidityProvider}`);
        assert(expectedDAIBalanceLiquidityProvider === actualDAIBalanceLiquidityProvider,
            `Incorrect DAI balance on Liquidity Provider for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceLiquidityProvider}, expected: ${expectedDAIBalanceLiquidityProvider}`);

        assert(expectedIpDAIBalanceUserThree === actualIpDAIBalanceUserThree,
            `Incorrect ipToken DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualIpDAIBalanceUserThree}, expected: ${expectedIpDAIBalanceUserThree}`);
        assert(expectedDAIBalanceUserThree === actualDAIBalanceUserThree,
            `Incorrect DAI balance on user for asset ${testData.tokenDai.address} actual: ${actualDAIBalanceUserThree}, expected: ${expectedDAIBalanceUserThree}`);

    });
    //TODO: add tests for pausable methods
});
