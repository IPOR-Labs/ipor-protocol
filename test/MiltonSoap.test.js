const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_18_DECIMALS,
    COLLATERALIZATION_FACTOR_6DEC,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_3_6DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_6DEC,
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
    PERIOD_1_DAY_IN_SECONDS,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_28_DAYS_IN_SECONDS,
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
    setupDefaultSpreadConstants,
    grantAllSpreadRoles,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("MiltonSoap", () => {
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
		await grantAllSpreadRoles(data, admin, userOne);
        await setupDefaultSpreadConstants(data, userOne);
    });
    it("should calculate soap, no derivatives, soap equal 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userTwo],
            ["DAI"],
            data,
            libraries
        );
        const params = {
            asset: testData.tokenDai.address,
            calculateTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };
        const expectedSoap = ZERO;

        //when
        const actualSoapStruct = await calculateSoap(params);
        const actualSoap = BigInt(actualSoapStruct.soap);

        //then
        expect(
            expectedSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${expectedSoap}`
        ).to.be.eq(actualSoap);
    });

    it("should calculate soap, DAI, pay fixed, add position, calculate now", async () => {
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
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_5_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI, pay fixed, add position, calculate after 25 days", async () => {
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

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);

        const expectedSoap = BigInt("-68083420969966832317");

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp:
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI, rec fixed, add position, calculate now", async () => {
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
        let direction = 1;
        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI, rec fixed, add position, calculate after 25 days", async () => {
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
        let direction = 1;
        let openerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);

        const expectedSoap = BigInt("-68083420969966791467");

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp:
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI, pay fixed, add and remove position", async () => {
        // given
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
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);

        let endTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(1, endTimestamp);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: endTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI, rec fixed, add and remove position", async () => {
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
        let direction = 1;
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);

        const expectedSoap = ZERO;
        let endTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_10_000_18DEC,
                derivativeParams.openTimestamp
            );

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(1, endTimestamp);

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp:
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI add pay fixed, DAI add rec fixed, 18 decimals", async () => {
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
        let firstDerivativeDirection = 0;
        let secondDerivativeDirection = 1;

        let openerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: firstDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const secondDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: secondDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                firstDerivativeParams.asset,
                BigInt(2) * USD_14_000_18DEC,
                openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                firstDerivativeParams.asset,
                iporValueBeforOpenPosition,
                openTimestamp
            );
        await openPositionFunc(firstDerivativeParams);
        await openPositionFunc(secondDerivativeParams);

        const expectedSoap = BigInt("-136166841939933623785");

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(soapParams);
    });

    it("should calculate soap, USDT add pay fixed, USDT add rec fixed, 6 decimals", async () => {
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
        let firstDerivativeDirection = 0;
        let secondDerivativeDirection = 1;

        let openerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_6DEC,
            direction: firstDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const secondDerivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_6DEC,
            direction: secondDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                firstDerivativeParams.asset,
                BigInt(2) * USD_14_000_6DEC,
                openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                firstDerivativeParams.asset,
                iporValueBeforOpenPosition,
                openTimestamp
            );
        await openPositionFunc(firstDerivativeParams);
        await openPositionFunc(secondDerivativeParams);

        const expectedSoap = BigInt("-136166841939933623785");

        //when
        const soapParams = {
            asset: testData.tokenUsdt.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI add pay fixed, USDT add pay fixed", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT"],
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

        let direction = 0;
        let openerUser = userTwo;

        let iporValueBeforOpenPositionDAI = PERCENTAGE_3_18DEC;
        let iporValueBeforOpenPositionUSDT = PERCENTAGE_3_18DEC;

        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeDAIParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const derivativeUSDTParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_6DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeDAIParams.asset,
                USD_14_000_18DEC,
                openTimestamp
            );
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeUSDTParams.asset,
                USD_14_000_6DEC,
                openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeDAIParams.asset,
                iporValueBeforOpenPositionDAI,
                derivativeDAIParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeUSDTParams.asset,
                iporValueBeforOpenPositionUSDT,
                derivativeUSDTParams.openTimestamp
            );

        //when
        await openPositionFunc(derivativeDAIParams);
        await openPositionFunc(derivativeUSDTParams);

        //then
        let expectedDAISoap = BigInt("-68083420969966832317");

        let expectedUSDTSoap = BigInt("-68083420969966832317");

        const soapDAIParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp:
                derivativeDAIParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedDAISoap,
            from: userTwo,
        };
        await assertSoap(soapDAIParams);

        const soapUSDTParams = {
            asset: testData.tokenUsdt.address,
            calculateTimestamp:
                derivativeUSDTParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedUSDTSoap,
            from: userTwo,
        };
        await assertSoap(soapUSDTParams);
    });

    it("should calculate soap, DAI add pay fixed, DAI add rec fixed, close rec fixed position", async () => {
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

        let payFixDerivativeDirection = 0;
        let recFixDerivativeDirection = 1;

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: payFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: recFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                payFixDerivativeParams.asset,
                BigInt(2) * USD_14_000_18DEC,
                openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                payFixDerivativeParams.asset,
                iporValueBeforOpenPosition,
                openTimestamp
            );
        await openPositionFunc(payFixDerivativeParams);
        await openPositionFunc(recFixDerivativeParams);

        let endTimestamp =
            recFixDerivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(2, endTimestamp);

        //then
        const expectedSoap = BigInt("-68083420969966832317");

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI add pay fixed, DAI add rec fixed, remove pay fixed position after 25 days", async () => {
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

        let payFixDerivativeDirection = 0;
        let recFixDerivativeDirection = 1;

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: payFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: recFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                payFixDerivativeParams.asset,
                BigInt(2) * USD_14_000_18DEC,
                openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                payFixDerivativeParams.asset,
                iporValueBeforOpenPosition,
                openTimestamp
            );
        await openPositionFunc(payFixDerivativeParams);
        await openPositionFunc(recFixDerivativeParams);

        let endTimestamp =
            recFixDerivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(1, endTimestamp);

        //then
        const expectedSoap = BigInt("-68083420969966791467");

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI add pay fixed, USDT add rec fixed, remove rec fixed position after 25 days", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI", "USDT"],
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

        let payFixDerivativeDAIDirection = 0;
        let recFixDerivativeUSDTDirection = 1;

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenPositionDAI = PERCENTAGE_3_18DEC;
        let iporValueBeforOpenPositionUSDT = PERCENTAGE_3_18DEC;

        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeDAIParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: payFixDerivativeDAIDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeUSDTParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_6DEC,
            direction: recFixDerivativeUSDTDirection,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                payFixDerivativeDAIParams.asset,
                USD_14_000_18DEC,
                openTimestamp
            );
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                recFixDerivativeUSDTParams.asset,
                USD_14_000_6DEC,
                openTimestamp
            );

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                payFixDerivativeDAIParams.asset,
                iporValueBeforOpenPositionDAI,
                openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                recFixDerivativeUSDTParams.asset,
                iporValueBeforOpenPositionUSDT,
                openTimestamp
            );

        await openPositionFunc(payFixDerivativeDAIParams);
        await openPositionFunc(recFixDerivativeUSDTParams);

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                recFixDerivativeUSDTParams.asset,
                USD_10_000_6DEC,
                openTimestamp
            );

        let endTimestamp =
            recFixDerivativeUSDTParams.openTimestamp +
            PERIOD_25_DAYS_IN_SECONDS;

        //when
        await data.milton
            .connect(closerUser)
            .test_closePosition(2, endTimestamp);

        //then
        const expectedSoapDAI = BigInt("-68083420969966832317");

        const soapParamsDAI = {
            asset: testData.tokenDai.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoapDAI,
            from: userTwo,
        };

        await assertSoap(soapParamsDAI);
    });

    it("should calculate soap, DAI add pay fixed, change ibtPrice, wait 25 days and then calculate soap, 18 decimals", async () => {
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
        let iporValueAfterOpenPosition = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueAfterOpenPosition,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                PERCENTAGE_6_18DEC,
                calculationTimestamp
            );

        const expectedSoap = BigInt("7897676832516150157812");

        //when
        //then
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate soap, USDT add pay fixed, change ibtPrice, wait 25 days and then calculate soap, 6 decimals", async () => {
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

        let direction = 0;
        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let iporValueAfterOpenPosition = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_6DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_6DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        await openPositionFunc(derivativeParams);

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueAfterOpenPosition,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                PERCENTAGE_6_6DEC,
                calculationTimestamp
            );

        const expectedSoap = BigInt("7897676832516150157812");

        //when
        //then
        const soapParams = {
            asset: testData.tokenUsdt.address,
            calculateTimestamp: calculationTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI add pay fixed, change ibtPrice, calculate soap after 28 days and after 50 days and compare", async () => {
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
        let iporValueAfterOpenPosition = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp25days =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp28days =
            derivativeParams.openTimestamp + PERIOD_28_DAYS_IN_SECONDS;
        let calculationTimestamp50days =
            derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueAfterOpenPosition,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                PERCENTAGE_6_18DEC,
                calculationTimestamp25days
            );

        const expectedSoap28Days = BigInt("7914016853548942207644");
        const expectedSoap50Days = BigInt("8033843674456083840150");

        //when
        //then
        const soapParams28days = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp28days,
            expectedSoap: expectedSoap28Days,
            from: userTwo,
        };
        await assertSoap(soapParams28days);

        const soapParams50days = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap50Days,
            from: userTwo,
        };
        await assertSoap(soapParams50days);
    });

    it("should calculate soap, DAI add pay fixed, wait 25 days, DAI add pay fixed, wait 25 days and then calculate soap", async () => {
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

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        let calculationTimestamp50days =
            derivativeParams25days.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParamsFirst.asset,
                BigInt(2) * USD_14_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParamsFirst.openTimestamp
            );
        await openPositionFunc(derivativeParamsFirst);
        await openPositionFunc(derivativeParams25days);

        //then
        const expectedSoap = BigInt("-204669094617849711707");

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate soap, DAI add pay fixed, wait 25 days, update IPOR and DAI add pay fixed, wait 25 days update IPOR and then calculate soap", async () => {
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

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        let calculationTimestamp50days =
            derivativeParams25days.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParamsFirst.asset,
                BigInt(2) * USD_14_000_18DEC,
                openTimestamp
            );

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParamsFirst.openTimestamp
            );
        await openPositionFunc(derivativeParamsFirst);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParams25days.openTimestamp
            );
        await openPositionFunc(derivativeParams25days);
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                calculationTimestamp50days
            );

        //then
        const expectedSoap = BigInt("-204669094617849711707");

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(soapParams);
    });

    it("should calculate EXACTLY the same SOAP with and without update IPOR Index with the same indexValue, DAI add pay fixed, 25 and 50 days period", async () => {
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
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp25days =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp50days =
            derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS;
        let soapBeforeUpdateIndex = null;

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            from: userTwo,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                openTimestamp
            );

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openPositionFunc(derivativeParams);

        let soapBeforeUpdateIndexStruct = await calculateSoap(soapParams);
        soapBeforeUpdateIndex = BigInt(soapBeforeUpdateIndexStruct.soap);

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                calculationTimestamp25days
            );
        let soapUpdateIndexAfter25DaysStruct = await calculateSoap(soapParams);
        let soapUpdateIndexAfter25Days = BigInt(
            soapUpdateIndexAfter25DaysStruct.soap
        );

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                calculationTimestamp50days
            );
        let soapUpdateIndexAfter50DaysStruct = await calculateSoap(soapParams);
        let soapUpdateIndexAfter50Days = BigInt(
            soapUpdateIndexAfter50DaysStruct.soap
        );

        //then
        const expectedSoap = BigInt("-136166841939933664635");

        expect(
            expectedSoap,
            `Incorrect SOAP before update index for asset ${soapParams.asset} actual: ${soapBeforeUpdateIndex}, expected: ${expectedSoap}`
        ).to.be.eq(soapBeforeUpdateIndex);
        expect(
            expectedSoap,
            `Incorrect SOAP update index after 25 days for asset ${soapParams.asset} actual: ${soapUpdateIndexAfter25Days}, expected: ${expectedSoap}`
        ).to.be.eq(soapUpdateIndexAfter25Days);
        expect(
            expectedSoap,
            `Incorrect SOAP update index after 50 days for asset ${soapParams.asset} actual: ${soapUpdateIndexAfter50Days}, expected: ${expectedSoap}`
        ).to.be.eq(soapUpdateIndexAfter50Days);
    });

    it("should calculate NEGATIVE SOAP, DAI add pay fixed, wait 25 days, update ibtPrice after derivative opened, soap should be negative right after opened position and updated ibtPrice", async () => {
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
        let iporValueAfterOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        let firstUpdateIndexTimestamp = openTimestamp;
        let secondUpdateIndexTimestamp =
            firstUpdateIndexTimestamp + PERIOD_1_DAY_IN_SECONDS;

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: direction,
            openTimestamp: secondUpdateIndexTimestamp,
            from: openerUser,
        };

        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParamsFirst.asset,
                USD_14_000_18DEC,
                openTimestamp
            );
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                firstUpdateIndexTimestamp
            );
        await openPositionFunc(derivativeParamsFirst);

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParamsFirst.asset,
                iporValueAfterOpenPosition,
                secondUpdateIndexTimestamp
            );

        let rightAfterOpenedPositionTimestamp =
            secondUpdateIndexTimestamp + 100;

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: rightAfterOpenedPositionTimestamp,
            expectedSoap: 0,
            from: userTwo,
        };
        const actualSoapStruct = await calculateSoap(soapParams);
        const actualSoap = BigInt(actualSoapStruct.soap);

        //then
        expect(parseInt(actualSoap)).to.be.below(
            0,
            `SOAP is positive but should be negative, actual: ${actualSoap}`
        );
    });

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

    const assertSoap = async (params) => {
        const actualSoapStruct = await calculateSoap(params);
        const actualSoap = BigInt(actualSoapStruct.soap);

        //then
        expect(
            params.expectedSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`
        ).to.be.eq(actualSoap);
    };

    const calculateSoap = async (params) => {
        return await data.milton
            .connect(params.from)
            .test_calculateSoap(params.asset, params.calculateTimestamp);
    };
});
