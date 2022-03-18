const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    LEVERAGE_6DEC,
    LEVERAGE_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_6DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_120_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_14_000_18DEC,
    USD_28_000_18DEC,
    USD_14_000_6DEC,
    USD_28_000_6DEC,
    ZERO,
    PERIOD_1_DAY_IN_SECONDS,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_28_DAYS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("MiltonSoap", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });
    it("should calculate soap, no derivatives, soap equal 0", async () => {
        //given
        let testData = await prepareTestData([admin, userTwo], ["DAI"], data, 0, 1, 0);
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
            0,
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

        let openerUserAddress = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_5_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
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
            0,
            0,
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

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        const expectedSoap = BigInt("-68267191075554066594");

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
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
            0,
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
        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
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
            0,
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
        let openerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParams);

        const expectedSoap = BigInt("-68267191075554025634");

        //when
        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
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
            0,
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
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        let endTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

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
            0,
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
        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapReceiveFixed(testData, derivativeParams);

        const expectedSoap = ZERO;
        let endTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(TC_TOTAL_AMOUNT_10_000_18DEC, derivativeParams.openTimestamp);

        //when
        await testData.miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
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
            0,
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

        let openerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const secondDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_18DEC, openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(firstDerivativeParams.asset, iporValueBeforOpenSwap, openTimestamp);
        await openSwapPayFixed(testData, firstDerivativeParams);
        await openSwapReceiveFixed(testData, secondDerivativeParams);

        const expectedSoap = BigInt("-136534382151108092229");

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

        let openerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const secondDerivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_6DEC, openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(firstDerivativeParams.asset, iporValueBeforOpenSwap, openTimestamp);
        await openSwapPayFixed(testData, firstDerivativeParams);
        await openSwapReceiveFixed(testData, secondDerivativeParams);

        const expectedSoap = BigInt("-136534382151108092229");

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
            0,
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

        let iporValueBeforOpenSwapDAI = PERCENTAGE_3_18DEC;
        let iporValueBeforOpenSwapUSDT = PERCENTAGE_3_18DEC;

        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeDAIParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const derivativeUSDTParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, openTimestamp);
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeDAIParams.asset,
                iporValueBeforOpenSwapDAI,
                derivativeDAIParams.openTimestamp
            );
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeUSDTParams.asset,
                iporValueBeforOpenSwapUSDT,
                derivativeUSDTParams.openTimestamp
            );

        //when
        await openSwapPayFixed(testData, derivativeDAIParams);
        await openSwapPayFixed(testData, derivativeUSDTParams);

        //then
        let expectedDAISoap = BigInt("-68267191075554066594");

        let expectedUSDTSoap = BigInt("-68267191075554066594");

        const soapDAIParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: derivativeDAIParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedDAISoap,
            from: userTwo,
        };
        await assertSoap(testData, soapDAIParams);

        const soapUSDTParams = {
            asset: testData.tokenUsdt.address,
            calculateTimestamp: derivativeUSDTParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
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
            0,
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

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_18DEC, openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(payFixDerivativeParams.asset, iporValueBeforOpenSwap, openTimestamp);
        await openSwapPayFixed(testData, payFixDerivativeParams);
        await openSwapReceiveFixed(testData, recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await testData.miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(2, endTimestamp);

        //then
        const expectedSoap = BigInt("-68267191075554066594");

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
            0,
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

        let openerUser = userTwo;
        let closerUser = userTwo;
        let iporValueBeforOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_18DEC, openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(payFixDerivativeParams.asset, iporValueBeforOpenSwap, openTimestamp);
        await openSwapPayFixed(testData, payFixDerivativeParams);
        await openSwapReceiveFixed(testData, recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);

        //then
        const expectedSoap = BigInt("-68267191075554025634");

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
            0,
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
        let iporValueBeforOpenSwapDAI = PERCENTAGE_3_18DEC;
        let iporValueBeforOpenSwapUSDT = PERCENTAGE_3_18DEC;

        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeDAIParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        const recFixDerivativeUSDTParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                payFixDerivativeDAIParams.asset,
                iporValueBeforOpenSwapDAI,
                openTimestamp
            );
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                recFixDerivativeUSDTParams.asset,
                iporValueBeforOpenSwapUSDT,
                openTimestamp
            );

        await openSwapPayFixed(testData, payFixDerivativeDAIParams);
        await openSwapReceiveFixed(testData, recFixDerivativeUSDTParams);

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_6DEC, openTimestamp);

        let endTimestamp = recFixDerivativeUSDTParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await testData.miltonUsdt.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);

        //then
        const expectedSoapDAI = BigInt("-68267191075554066594");

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
            0,
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

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let iporValueAfterOpenSwap = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenSwap,
                derivativeParams.openTimestamp
            );
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(derivativeParams.asset, PERCENTAGE_6_18DEC, calculationTimestamp);

        const expectedSoap = BigInt("7918994164764269327487");

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

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let iporValueAfterOpenSwap = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenSwap,
                derivativeParams.openTimestamp
            );
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(derivativeParams.asset, PERCENTAGE_6_6DEC, calculationTimestamp);

        const expectedSoap = BigInt("7918994164764269327487");

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
            0,
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

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let iporValueAfterOpenSwap = PERCENTAGE_120_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp25days = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp28days = derivativeParams.openTimestamp + PERIOD_28_DAYS_IN_SECONDS;
        let calculationTimestamp50days = derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueAfterOpenSwap,
                derivativeParams.openTimestamp
            );
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(derivativeParams.asset, PERCENTAGE_6_18DEC, calculationTimestamp25days);

        const expectedSoap28Days = BigInt("7935378290622402313573");
        const expectedSoap50Days = BigInt("8055528546915377478426");

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
            0,
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

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        let calculationTimestamp50days =
            derivativeParams25days.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_18DEC, derivativeParamsFirst.openTimestamp);

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);
        await openSwapPayFixed(testData, derivativeParams25days);

        //then
        const expectedSoap = BigInt("-205221535441070939561");

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
            0,
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

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };
        const derivativeParams25days = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUser,
        };
        let calculationTimestamp50days =
            derivativeParams25days.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigInt(2) * USD_28_000_18DEC, openTimestamp);

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParamsFirst.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                derivativeParams25days.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams25days);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                calculationTimestamp50days
            );

        //then
        const expectedSoap = BigInt("-205221535441070939561");

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
            0,
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

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: openTimestamp,
            from: openerUser,
        };

        let calculationTimestamp25days = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp50days = derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS;
        let soapBeforeUpdateIndex = null;

        const soapParams = {
            asset: testData.tokenDai.address,
            calculateTimestamp: calculationTimestamp50days,
            from: userTwo,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, openTimestamp);

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                derivativeParams.openTimestamp
            );
        await openSwapPayFixed(testData, derivativeParams);

        let soapBeforeUpdateIndexStruct = await calculateSoap(testData, soapParams);
        soapBeforeUpdateIndex = BigInt(soapBeforeUpdateIndexStruct.soap);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                calculationTimestamp25days
            );
        let soapUpdateIndexAfter25DaysStruct = await calculateSoap(testData, soapParams);
        let soapUpdateIndexAfter25Days = BigInt(soapUpdateIndexAfter25DaysStruct.soap);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                iporValueBeforeOpenSwap,
                calculationTimestamp50days
            );
        let soapUpdateIndexAfter50DaysStruct = await calculateSoap(testData, soapParams);
        let soapUpdateIndexAfter50Days = BigInt(soapUpdateIndexAfter50DaysStruct.soap);

        //then
        const expectedSoap = BigInt("-136534382151108133189");

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

    it("should calculate NEGATIVE SOAP, DAI add pay fixed, wait 25 days, update ibtPrice after swap opened, soap should be negative right after opened position and updated ibtPrice", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
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

        let openerUser = userTwo;
        let iporValueBeforeOpenSwap = PERCENTAGE_3_18DEC;
        let iporValueAfterOpenSwap = PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        let firstUpdateIndexTimestamp = openTimestamp;
        let secondUpdateIndexTimestamp = firstUpdateIndexTimestamp + PERIOD_1_DAY_IN_SECONDS;

        const derivativeParamsFirst = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: secondUpdateIndexTimestamp,
            from: openerUser,
        };

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueBeforeOpenSwap,
                firstUpdateIndexTimestamp
            );
        await openSwapPayFixed(testData, derivativeParamsFirst);

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParamsFirst.asset,
                iporValueAfterOpenSwap,
                secondUpdateIndexTimestamp
            );

        let rightAfterOpenedPositionTimestamp = secondUpdateIndexTimestamp + 100;

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
