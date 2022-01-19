const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    COLLATERALIZATION_FACTOR_6DEC,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_6DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_120_18DEC,
    USD_10_000_18DEC,
    USD_10_000_6DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
    ZERO,
    PERIOD_1_DAY_IN_SECONDS,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_28_DAYS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    getLibraries,
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
        const actualSoapStruct = await calculateSoap(testData, params);
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

        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_5_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
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
        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        const expectedSoap = BigInt("-68083420969966832317");

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp:
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
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
        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParams);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
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
        let openerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenPosition,
                derivativeParams.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParams);

        const expectedSoap = BigInt("-68083420969966791467");

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp:
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
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
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenPosition,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        let endTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapPayFixed(1, endTimestamp);

        const expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: endTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
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
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenPosition,
                derivativeParams.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParams);

        const expectedSoap = ZERO;
        let endTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_10_000_18DEC,
                derivativeParams.openTimestamp
            );

        //when
        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapReceiveFixed(1, endTimestamp);

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp:
                derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
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

        let openerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const secondDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_14_000_18DEC, openTimestamp);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                firstDerivativeParams.asset,
                iporValueBeforOpenPosition,
                openTimestamp
            );
        await openSwapPayFixed(testData, firstDerivativeParams);
        await openSwapReceiveFixed(testData, secondDerivativeParams);

        const expectedSoap = BigInt("-136166841939933623785");

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
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

        let openerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const secondDerivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_14_000_6DEC, openTimestamp);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                firstDerivativeParams.asset,
                iporValueBeforOpenPosition,
                openTimestamp
            );
        await openSwapPayFixed(testData, firstDerivativeParams);
        await openSwapReceiveFixed(testData, secondDerivativeParams);

        const expectedSoap = BigInt("-136166841939933623785");

        //when
        const soapParams = {
            asset: testData.tokenUsdt.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
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

        let openerUser = userTwo;

        let iporValueBeforOpenPositionDAI = PERCENTAGE_3_18DEC;
        let iporValueBeforOpenPositionUSDT = PERCENTAGE_3_18DEC;

        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeDAIParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const derivativeUSDTParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_14_000_18DEC, openTimestamp);
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_14_000_6DEC, openTimestamp);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeDAIParams.asset,
                iporValueBeforOpenPositionDAI,
                derivativeDAIParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeUSDTParams.asset,
                iporValueBeforOpenPositionUSDT,
                derivativeUSDTParams.openTimestamp
            );

        //when
        await openSwapPayFixed(testData, derivativeDAIParams);
        await openSwapPayFixed(testData, derivativeUSDTParams);

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
        await assertSoap(testData, soapDAIParams);

        const soapUSDTParams = {
            asset: testData.tokenUsdt.address,
            calculateTimestamp:
                derivativeUSDTParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedUSDTSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapUSDTParams);
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

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_14_000_18DEC, openTimestamp);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                payFixDerivativeParams.asset,
                iporValueBeforOpenPosition,
                openTimestamp
            );
        await openSwapPayFixed(testData, payFixDerivativeParams);
        await openSwapReceiveFixed(testData, recFixDerivativeParams);

        let endTimestamp =
            recFixDerivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapReceiveFixed(2, endTimestamp);

        //then
        const expectedSoap = BigInt("-68083420969966832317");

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
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

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_14_000_18DEC, openTimestamp);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                payFixDerivativeParams.asset,
                iporValueBeforOpenPosition,
                openTimestamp
            );
        await openSwapPayFixed(testData, payFixDerivativeParams);
        await openSwapReceiveFixed(testData, recFixDerivativeParams);

        let endTimestamp =
            recFixDerivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await testData.miltonDai
            .connect(closerUser)
            .itfCloseSwapPayFixed(1, endTimestamp);

        //then
        const expectedSoap = BigInt("-68083420969966791467");

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo,
        };

        await assertSoap(testData, soapParams);
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
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeUSDTParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_14_000_18DEC, openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_14_000_6DEC, openTimestamp);

        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                payFixDerivativeDAIParams.asset,
                iporValueBeforOpenPositionDAI,
                openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                recFixDerivativeUSDTParams.asset,
                iporValueBeforOpenPositionUSDT,
                openTimestamp
            );

        await openSwapPayFixed(testData, payFixDerivativeDAIParams);
        await openSwapReceiveFixed(testData, recFixDerivativeUSDTParams);

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_6DEC, openTimestamp);

        let endTimestamp =
            recFixDerivativeUSDTParams.openTimestamp +
            PERIOD_25_DAYS_IN_SECONDS;

        //when
        await testData.miltonUsdt
            .connect(closerUser)
            .itfCloseSwapReceiveFixed(1, endTimestamp);

        //then
        const expectedSoapDAI = BigInt("-68083420969966832317");

        const soapParamsDAI = {
            asset: testData.tokenDai.address,
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoapDAI,
            from: userTwo,
        };

        await assertSoap(testData, soapParamsDAI);
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

        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let iporValueAfterOpenPosition = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenPosition,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
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
        await assertSoap(testData, soapParams);
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

        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let iporValueAfterOpenPosition = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_6DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenPosition,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
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
        await assertSoap(testData, soapParams);
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

        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let iporValueAfterOpenPosition = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp25days =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp28days =
            derivativeParams.openTimestamp + PERIOD_28_DAYS_IN_SECONDS;
        let calculationTimestamp50days =
            derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenPosition,
                derivativeParams.openTimestamp
            );
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
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
        await assertSoap(testData, soapParams28days);

        const soapParams50days = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap50Days,
            from: userTwo,
        };
        await assertSoap(testData, soapParams50days);
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

        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        let calculationTimestamp50days =
            derivativeParams25days.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                BigInt(2) * USD_14_000_18DEC,
                derivativeParamsFirst.openTimestamp
            );

        //when
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);
        await openSwapPayFixed(testData, derivativeParams25days);

        //then
        const expectedSoap = BigInt("-204669094617849711707");

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo,
        };
        await assertSoap(testData, soapParams);
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

        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        let calculationTimestamp50days =
            derivativeParams25days.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_14_000_18DEC, openTimestamp);

        //when
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                derivativeParams25days.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams25days);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
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
        await assertSoap(testData, soapParams);
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

        let openerUser = userTwo;
        let iporValueBeforeOpenPosition = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
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

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_14_000_18DEC, openTimestamp);

        //when
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        let soapBeforeUpdateIndexStruct = await calculateSoap(
            testData,
            soapParams
        );
        soapBeforeUpdateIndex = BigInt(soapBeforeUpdateIndexStruct.soap);

        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                calculationTimestamp25days
            );
        let soapUpdateIndexAfter25DaysStruct = await calculateSoap(
            testData,
            soapParams
        );
        let soapUpdateIndexAfter25Days = BigInt(
            soapUpdateIndexAfter25DaysStruct.soap
        );

        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenPosition,
                calculationTimestamp50days
            );
        let soapUpdateIndexAfter50DaysStruct = await calculateSoap(
            testData,
            soapParams
        );
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
            openTimestamp: secondUpdateIndexTimestamp,
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_14_000_18DEC, openTimestamp);
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenPosition,
                firstUpdateIndexTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        //when
        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
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
        const actualSoapStruct = await calculateSoap(testData, soapParams);
        const actualSoap = BigInt(actualSoapStruct.soap);

        //then
        expect(parseInt(actualSoap)).to.be.below(
            0,
            `SOAP is positive but should be negative, actual: ${actualSoap}`
        );
    });

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

    const assertSoap = async (testData, params) => {
        const actualSoapStruct = await calculateSoap(testData, params);
        const actualSoap = BigInt(actualSoapStruct.soap);

        //then
        expect(
            params.expectedSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`
        ).to.be.eq(actualSoap);
    };

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
});
