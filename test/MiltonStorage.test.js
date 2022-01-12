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
    grantAllSpreadRoles,
    setupTokenUsdtInitialValuesForUsers,
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    setupIpTokenDaiInitialValues,
    setupIpTokenUsdtInitialValues,
    setupTokenDaiInitialValuesForUsers,
    setupDefaultSpreadConstants,
} = require("./Utils");

describe("MiltonStorage", () => {
    let data = null;
    let admin,
        userOne,
        userTwo,
        userThree,
        liquidityProvider,
        miltonStorageAddress;
    let libraries;

    before(async () => {
        libraries = await getLibraries();
        [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
            miltonStorageAddress,
        ] = await ethers.getSigners();
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

    it("should update Milton Storage when open position, caller has rights to update", async () => {
        //given
        let testData = await prepareTestData(
            [
                admin,
                userOne,
                userTwo,
                userThree,
                liquidityProvider,
                miltonStorageAddress,
            ],
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
            [admin, userOne, liquidityProvider],
            testData
        );

        await data.iporConfiguration.setMilton(miltonStorageAddress.address);

        //when
        testData.miltonStorage
            .connect(miltonStorageAddress)
            .updateStorageWhenOpenPosition(
                await preprareDerivativeStruct18DecSimpleCase1(testData)
            );
        //then
        //assert(true); //no exception this line is achieved
    });

    it("should NOT update Milton Storage when open position, caller dont have rights to update", async () => {
        //given
        let testData = await prepareTestData(
            [
                admin,
                userOne,
                userTwo,
                userThree,
                liquidityProvider,
                miltonStorageAddress,
            ],
            ["DAI"],
            data,
            libraries
        );
        const derivativeStruct = await preprareDerivativeStruct18DecSimpleCase1(
            testData
        );
        await assertError(
            //when
            testData.miltonStorage
                .connect(userThree)
                .callStatic.updateStorageWhenOpenPosition(derivativeStruct),
            //then
            "IPOR_1"
        );
    });

    it("should update Milton Storage when close position, caller has rights to update, DAI 18 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [
                admin,
                userOne,
                userTwo,
                userThree,
                liquidityProvider,
                miltonStorageAddress,
            ],
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openPositionFunc(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress.address);

        //when
        testData.miltonStorage
            .connect(miltonStorageAddress)
            .updateStorageWhenClosePosition(
                userTwo.address,
                derivativeItem,
                BigInt("10000000000000000000"),
                closePositionTimestamp
            );
        //then
        // assert(true); //no exception this line is achieved
    });

    it("should update Milton Storage when close position, caller has rights to update, USDT 6 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [
                admin,
                userOne,
                userTwo,
                userThree,
                liquidityProvider,
                miltonStorageAddress,
            ],
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const derivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_6DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_6DEC,
                derivativeParams.openTimestamp
            );

        await openPositionFunc(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress.address);

        //when
        testData.miltonStorage
            .connect(miltonStorageAddress)
            .updateStorageWhenClosePosition(
                userTwo.address,
                derivativeItem,
                BigInt("10000000"),
                closePositionTimestamp
            );
        //then
        //assert(true); //no exception this line is achieved
    });

    it("should NOT update Milton Storage when close position, caller dont have rights to update", async () => {
        // given
        let testData = await prepareTestData(
            [
                admin,
                userOne,
                userTwo,
                userThree,
                liquidityProvider,
                miltonStorageAddress,
            ],
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );
        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.warren
            .connect(userOne)
            .test_updateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph
            .connect(liquidityProvider)
            .test_provideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openPositionFunc(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress.address);

        //when
        await assertError(
            testData.miltonStorage
                .connect(userThree)
                .updateStorageWhenClosePosition(
                    userTwo.address,
                    derivativeItem,
                    BigInt("10000000000000000000"),
                    closePositionTimestamp
                ),
            //then
            "IPOR_1"
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

    const preprareDerivativeStruct18DecSimpleCase1 = async (testData) => {
        let openingTimestamp = Math.floor(Date.now() / 1000);
        let closePositionTimestamp =
            openingTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        return {
            id: 1,
            state: 0,
            buyer: userTwo.address,
            asset: testData.tokenDai.address,
            direction: 0,
            collateral: BigInt("1000000000000000000000"),
            fee: {
                liquidationDepositAmount: BigInt("20000000000000000000"),
                openingAmount: 123,
                iporPublicationAmount: 123,
                spreadValue: 123,
            },
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            notionalAmount: 123,
            startingTimestamp: openingTimestamp,
            endingTimestamp: closePositionTimestamp,
            indicator: {
                iporIndexValue: 123,
                ibtPrice: 123,
                ibtQuantity: 123,
                fixedInterestRate: 234,
            },
        };
    };
});
