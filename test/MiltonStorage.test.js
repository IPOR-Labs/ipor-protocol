const testUtils = require("./TestUtils.js");

contract('MiltonStorage', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress, _] = accounts;

    let data = null;

    before(async () => {
        data = await testUtils.prepareData();
    });

    it('should update Milton Storage when open position, caller has rights to update', async () => {

        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, liquidityProvider], testData);

        await data.iporConfiguration.setMilton(miltonStorageAddress);

        //when
        testData.miltonStorage.updateStorageWhenOpenPosition(await preprareDerivativeStruct18DecSimpleCase1(testData), {from: miltonStorageAddress});
        //then
        assert(true);//no exception this line is achieved

    });

    it('should NOT update Milton Storage when open position, caller dont have rights to update', async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress], ["DAI"], data);
        await testUtils.assertError(
            //when
            testData.miltonStorage.updateStorageWhenOpenPosition(await preprareDerivativeStruct18DecSimpleCase1(testData), {from: userThree}),
            //then
            'IPOR_1'
        );
    });

    it('should update Milton Storage when close position, caller has rights to update, DAI 18 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, liquidityProvider], testData);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await data.warren.test_updateIndex(derivativeParams.asset, testUtils.PERCENTAGE_5_18DEC, derivativeParams.openTimestamp, {from: userOne});
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});

        await openPositionFunc(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress);

        //when
        testData.miltonStorage.updateStorageWhenClosePosition(
            userTwo, derivativeItem, BigInt("10000000000000000000"), closePositionTimestamp, {from: miltonStorageAddress});
        //then
        assert(true);//no exception this line is achieved
    });

    it('should update Milton Storage when close position, caller has rights to update, USDT 6 decimals', async () => {
        //given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress], ["USDT"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "USDT", data, testData);
        await testUtils.setupTokenUsdtInitialValuesForUsers([admin, userOne, userTwo, liquidityProvider], testData);

        const derivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: testUtils.USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_6DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await data.warren.test_updateIndex(derivativeParams.asset, testUtils.PERCENTAGE_5_6DEC, derivativeParams.openTimestamp, {from: userOne});
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_6DEC, {from: liquidityProvider});

        await openPositionFunc(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress);

        //when
        testData.miltonStorage.updateStorageWhenClosePosition(
            userTwo, derivativeItem, BigInt("10000000"), closePositionTimestamp, {from: miltonStorageAddress});
        //then
        assert(true);//no exception this line is achieved
    });

    it('should NOT update Milton Storage when close position, caller dont have rights to update', async () => {

        // given
        let testData = await testUtils.prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress], ["DAI"], data);
        await testUtils.prepareApproveForUsers([userOne, userTwo, userThree, liquidityProvider], "DAI", data, testData);
        await testUtils.setupTokenDaiInitialValuesForUsers([admin, userOne, userTwo, liquidityProvider], testData);
        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await data.warren.test_updateIndex(derivativeParams.asset, testUtils.PERCENTAGE_5_18DEC, derivativeParams.openTimestamp, {from: userOne});
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph.provideLiquidity(derivativeParams.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider});

        await openPositionFunc(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress);

        //when
        await testUtils.assertError(
            testData.miltonStorage.updateStorageWhenClosePosition(
                userTwo, derivativeItem, BigInt("10000000000000000000"), closePositionTimestamp, {from: userThree}),
            //then
            'IPOR_1'
        );

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

    const preprareDerivativeStruct18DecSimpleCase1 = async (testData) => {
        let openingTimestamp = Math.floor(Date.now() / 1000);
        let closePositionTimestamp = openingTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        return {
            id: 1,
            state: 0,
            buyer: userTwo,
            asset: testData.tokenDai.address,
            direction: 0,
            collateral: BigInt("1000000000000000000000"),
            fee: {
                liquidationDepositAmount: BigInt("20000000000000000000"),
                openingAmount: 123,
                iporPublicationAmount: 123,
                spreadPayFixedValue: 123,
                spreadRecFixedValue: 123
            },
            collateralizationFactor: testUtils.COLLATERALIZATION_FACTOR_18DEC,
            notionalAmount: 123,
            startingTimestamp: openingTimestamp,
            endingTimestamp: closePositionTimestamp,
            indicator: {
                iporIndexValue: 123,
                ibtPrice: 123,
                ibtQuantity: 123,
                fixedInterestRate: 234
            },
            multiplicator: testUtils.TC_MULTIPLICATOR_18DEC
        };
    }
});