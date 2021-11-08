const testUtils = require("./TestUtils.js");

contract('MiltonSoap', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let data = null;
    let testData = null;

    before(async () => {
        data = await testUtils.prepareDataForBefore(accounts);
    });

    beforeEach(async () => {
        testData = await testUtils.prepareDataForBeforeEach(data);
    });

    it('should calculate soap, no derivatives, soap equal 0', async () => {
        //given
        const params = {
            asset: data.tokenDai.address,
            calculateTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        let expectedSoap = testUtils.ZERO;

        //when
        let actualSoapStruct = await calculateSoap(params)
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then

        assert(expectedSoap === actualSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${expectedSoap}`)
    });

    it('should calculate soap, DAI, pay fixed, add position, calculate now', async () => {

        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_5_18DEC;

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = testUtils.ZERO;

        //when
        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);

    });


    it('should calculate soap, DAI, pay fixed, add position, calculate after 25 days', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = BigInt("-62079701120797029831");

        //when
        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI, rec fixed, add position, calculate now', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 1;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = testUtils.ZERO;

        //when
        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI, rec fixed, add position, calculate after 25 days', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 1;
        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = BigInt("-62079701120796992583");

        //when
        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI, pay fixed, add and remove position', async () => {
        // given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let endTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await data.milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        let expectedSoap = testUtils.ZERO;

        //when
        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: endTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI, rec fixed, add and remove position', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 1;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = testUtils.ZERO;
        let endTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_10_000_18DEC, {from: liquidityProvider})

        //when
        await data.milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});


        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed, 18 decimals', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let firstDerivativeDirection = 0;
        let secondDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: firstDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const secondDerivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: secondDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(firstDerivativeParams.asset, BigInt(2) * testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(firstDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(firstDerivativeParams);
        await openPositionFunc(secondDerivativeParams);

        let expectedSoap = BigInt("-124159402241594022415");

        //when
        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });

    it('should calculate soap, USDT add pay fixed, USDT add rec fixed, 6 decimals', async () => {
        //given
        await testUtils.setupTokenUsdtInitialValues(data);
        let firstDerivativeDirection = 0;
        let secondDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.PERCENTAGE_3_6DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: data.tokenUsdt.address,
            totalAmount: testUtils.USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_6DEC,
            direction: firstDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const secondDerivativeParams = {
            asset: data.tokenUsdt.address,
            totalAmount: testUtils.USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_6DEC,
            direction: secondDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(firstDerivativeParams.asset, BigInt(2) * testUtils.USD_14_000_6DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(firstDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(firstDerivativeParams);
        await openPositionFunc(secondDerivativeParams);

        let expectedSoap = BigInt("-124159401");

        //when
        const soapParams = {
            asset: data.tokenUsdt.address,
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI add pay fixed, USDT add pay fixed', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupTokenUsdtInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;

        let iporValueBeforOpenPositionDAI = testUtils.PERCENTAGE_3_18DEC;
        let iporValueBeforOpenPositionUSDT = testUtils.PERCENTAGE_3_6DEC;

        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeDAIParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const derivativeUSDTParams = {
            asset: data.tokenUsdt.address,
            totalAmount: testUtils.USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_6DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.joseph.provideLiquidity(derivativeDAIParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.joseph.provideLiquidity(derivativeUSDTParams.asset, testUtils.USD_14_000_6DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeDAIParams.asset, iporValueBeforOpenPositionDAI, derivativeDAIParams.openTimestamp, {from: userOne});
        await data.warren.test_updateIndex(derivativeUSDTParams.asset, iporValueBeforOpenPositionUSDT, derivativeUSDTParams.openTimestamp, {from: userOne});

        //when
        await openPositionFunc(derivativeDAIParams);
        await openPositionFunc(derivativeUSDTParams);

        //then
        let expectedDAISoap = BigInt("-62079701120797029831");

        let expectedUSDTSoap = BigInt("-62061076");

        const soapDAIParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: derivativeDAIParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedDAISoap,
            from: userTwo
        }
        await assertSoap(soapDAIParams);

        const soapUSDTParams = {
            asset: data.tokenUsdt.address,
            calculateTimestamp: derivativeUSDTParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedUSDTSoap,
            from: userTwo
        }
        await assertSoap(soapUSDTParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed, close rec fixed position', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let payFixDerivativeDirection = 0;
        let recFixDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: payFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: recFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.joseph.provideLiquidity(payFixDerivativeParams.asset, BigInt(2) * testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(payFixDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(payFixDerivativeParams);
        await openPositionFunc(recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await data.milton.test_closePosition(2, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoap = BigInt("-62079701120797029831");

        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed, remove pay fixed position after 25 days', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let payFixDerivativeDirection = 0;
        let recFixDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: payFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: recFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.joseph.provideLiquidity(payFixDerivativeParams.asset, BigInt(2) * testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(payFixDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(payFixDerivativeParams);
        await openPositionFunc(recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await data.milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoap = BigInt("-62079701120796992583");

        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI add pay fixed, USDT add rec fixed, remove rec fixed position after 25 days', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        await testUtils.setupTokenUsdtInitialValues(data);
        let payFixDerivativeDAIDirection = 0;
        let recFixDerivativeUSDTDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPositionDAI = testUtils.PERCENTAGE_3_18DEC;
        let iporValueBeforOpenPositionUSDT = testUtils.PERCENTAGE_3_6DEC;

        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeDAIParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: payFixDerivativeDAIDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeUSDTParams = {
            asset: data.tokenUsdt.address,
            totalAmount: testUtils.USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_6DEC,
            direction: recFixDerivativeUSDTDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.joseph.provideLiquidity(payFixDerivativeDAIParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.joseph.provideLiquidity(recFixDerivativeUSDTParams.asset, testUtils.USD_14_000_6DEC, {from: liquidityProvider});

        await data.warren.test_updateIndex(payFixDerivativeDAIParams.asset, iporValueBeforOpenPositionDAI, openTimestamp, {from: userOne});
        await data.warren.test_updateIndex(recFixDerivativeUSDTParams.asset, iporValueBeforOpenPositionUSDT, openTimestamp, {from: userOne});

        await openPositionFunc(payFixDerivativeDAIParams);
        await openPositionFunc(recFixDerivativeUSDTParams);

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await data.joseph.provideLiquidity(recFixDerivativeUSDTParams.asset, testUtils.USD_10_000_6DEC, {from: liquidityProvider})

        let endTimestamp = recFixDerivativeUSDTParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await data.milton.test_closePosition(2, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoapDAI = BigInt("-62079701120797029831");

        const soapParamsDAI = {
            asset: data.tokenDai.address,
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoapDAI,
            from: userTwo
        }

        await assertSoap(soapParamsDAI);
    });

    it('should calculate soap, DAI add pay fixed, change ibtPrice, wait 25 days and then calculate soap, 18 decimals', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let iporValueAfterOpenPosition = testUtils.PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueAfterOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await data.warren.test_updateIndex(derivativeParams.asset, testUtils.PERCENTAGE_6_18DEC, calculationTimestamp, {from: userOne});

        let expectedSoap = BigInt("7201245330012453280259");

        //when
        //then
        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: calculationTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });

    it('should calculate soap, USDT add pay fixed, change ibtPrice, wait 25 days and then calculate soap, 6 decimals', async () => {
        //given
        await testUtils.setupTokenUsdtInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_6DEC;
        let iporValueAfterOpenPosition = testUtils.PERCENTAGE_120_6DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenUsdt.address,
            totalAmount: testUtils.USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_6DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_6DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueAfterOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await data.warren.test_updateIndex(derivativeParams.asset, testUtils.PERCENTAGE_6_6DEC, calculationTimestamp, {from: userOne});

        let expectedSoap = BigInt("7201265196");

        //when
        //then
        const soapParams = {
            asset: data.tokenUsdt.address,
            calculateTimestamp: calculationTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI add pay fixed, change ibtPrice, calculate soap after 28 days and after 50 days and compare', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let iporValueAfterOpenPosition = testUtils.PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp25days = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp28days = derivativeParams.openTimestamp + testUtils.PERIOD_28_DAYS_IN_SECONDS;
        let calculationTimestamp50days = derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS;

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueAfterOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await data.warren.test_updateIndex(derivativeParams.asset, testUtils.PERCENTAGE_6_18DEC, calculationTimestamp25days, {from: userOne});

        let expectedSoap28Days = BigInt("7216144458281444576607");
        let expectedSoap50Days = BigInt("7325404732254047356064");

        //when
        //then
        const soapParams28days = {
            asset: data.tokenDai.address,
            calculateTimestamp: calculationTimestamp28days,
            expectedSoap: expectedSoap28Days,
            from: userTwo
        }
        await assertSoap(soapParams28days);

        const soapParams50days = {
            asset: data.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap50Days,
            from: userTwo
        }
        await assertSoap(soapParams50days);
    });


    it('should calculate soap, DAI add pay fixed, wait 25 days, DAI add pay fixed, wait 25 days and then calculate soap', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        const derivativeParams25days = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        let calculationTimestamp50days = derivativeParams25days.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        await data.joseph.provideLiquidity(derivativeParamsFirst.asset, BigInt(2) * testUtils.USD_14_000_18DEC, {from: liquidityProvider});

        //when
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);
        await openPositionFunc(derivativeParams25days);

        //then
        let expectedSoap = BigInt("-186621001728821146220");

        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);

    });

    it('should calculate soap, DAI add pay fixed, wait 25 days, update IPOR and DAI add pay fixed, wait 25 days update IPOR and then calculate soap', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        const derivativeParams25days = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        let calculationTimestamp50days = derivativeParams25days.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.joseph.provideLiquidity(derivativeParamsFirst.asset, BigInt(2) * testUtils.USD_14_000_18DEC, {from: liquidityProvider});

        //when
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParams25days.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams25days);
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, calculationTimestamp50days, {from: userOne});

        //then
        let expectedSoap = BigInt("-186621001728821146220");

        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);

    });


    it('should calculate EXACTLY the same SOAP with and without update IPOR Index with the same indexValue, DAI add pay fixed, 25 and 50 days period', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp25days = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp50days = derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS;
        let soapBeforeUpdateIndex = null;

        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            from: userTwo
        }

        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});

        //when
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let soapBeforeUpdateIndexStruct = await calculateSoap(soapParams);
        soapBeforeUpdateIndex = BigInt(soapBeforeUpdateIndexStruct.soap);

        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, calculationTimestamp25days, {from: userOne});
        let soapUpdateIndexAfter25DaysStruct = await calculateSoap(soapParams);
        let soapUpdateIndexAfter25Days = BigInt(soapUpdateIndexAfter25DaysStruct.soap);

        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, calculationTimestamp50days, {from: userOne});
        let soapUpdateIndexAfter50DaysStruct = await calculateSoap(soapParams);
        let soapUpdateIndexAfter50Days = BigInt(soapUpdateIndexAfter50DaysStruct.soap);


        //then
        let expectedSoap = BigInt("-124159402241594059663");

        assert(expectedSoap === soapBeforeUpdateIndex,
            `Incorrect SOAP before update index for asset ${soapParams.asset} actual: ${soapBeforeUpdateIndex}, expected: ${expectedSoap}`);
        assert(expectedSoap === soapUpdateIndexAfter25Days,
            `Incorrect SOAP update index after 25 days for asset ${soapParams.asset} actual: ${soapUpdateIndexAfter25Days}, expected: ${expectedSoap}`);
        assert(expectedSoap === soapUpdateIndexAfter50Days,
            `Incorrect SOAP update index after 50 days for asset ${soapParams.asset} actual: ${soapUpdateIndexAfter50Days}, expected: ${expectedSoap}`);
    });


    it('should calculate NEGATIVE SOAP, DAI add pay fixed, wait 25 days, update ibtPrice after derivative opened, soap should be negative right after opened position and updated ibtPrice', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let iporValueAfterOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        let firstUpdateIndexTimestamp = openTimestamp;
        let secondUpdateIndexTimestamp = firstUpdateIndexTimestamp + testUtils.PERIOD_1_DAY_IN_SECONDS;

        const derivativeParamsFirst = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: secondUpdateIndexTimestamp,
            from: openerUserAddress
        }

        await data.joseph.provideLiquidity(derivativeParamsFirst.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, firstUpdateIndexTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        //when
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueAfterOpenPosition, secondUpdateIndexTimestamp, {from: userOne});

        let rightAfterOpenedPositionTimestamp = secondUpdateIndexTimestamp + 100;

        const soapParams = {
            asset: data.tokenDai.address,
            calculateTimestamp: rightAfterOpenedPositionTimestamp,
            expectedSoap: 0,
            from: userTwo
        }
        let actualSoapStruct = await calculateSoap(soapParams);
        let actualSoap = BigInt(actualSoapStruct.soap);


        //then
        assert(actualSoap < 0, `SOAP is positive but should be negative, actual: ${actualSoap}`);

    });

    const openPositionFunc = async (params) => {
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
            params.direction, {from: params.from});
    }

    const assertSoap = async (params) => {
        let actualSoapStruct = await calculateSoap(params);
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then
        assert(params.expectedSoap === actualSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`)
    }

    const calculateSoap = async (params) => {
        return await data.milton.test_calculateSoap.call(params.asset, params.calculateTimestamp, {from: params.from});
    }

});
