const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    COLLATERALIZATION_FACTOR_6DEC,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_3_6DEC,
    PERCENTAGE_5_18DEC,
    USD_10_000_18DEC,
    USD_10_000_6DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    assertError,
    getLibraries,
    grantAllSpreadRoles,
    setupTokenUsdtInitialValuesForUsers,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
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

        //when
        testData.miltonStorageDai
            .connect(miltonStorageAddress)
            .updateStorageWhenOpenSwapPayFixed(
                await preprareSwapPayFixedStruct18DecSimpleCase1(testData),
                BigInt("1500000000000000000000")
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
        const derivativeStruct =
            await preprareSwapPayFixedStruct18DecSimpleCase1(testData);
        await assertError(
            //when
            testData.miltonStorage
                .connect(userThree)
                .updateStorageWhenOpenSwapPayFixed(
                    derivativeStruct,
                    BigInt("1500000000000000000000")
                ),
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
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getSwapPayFixedItem(
            1
        );
        let closePositionTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress.address);

        //when
        testData.miltonStorage
            .connect(miltonStorageAddress)
            .updateStorageWhenCloseSwapPayFixed(
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
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                derivativeParams.asset,
                USD_14_000_6DEC,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getSwapPayFixedItem(
            1
        );
        let closePositionTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress.address);

        //when
        testData.miltonStorage
            .connect(miltonStorageAddress)
            .updateStorageWhenCloseSwapPayFixed(
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
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await data.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );
        await data.iporConfiguration.setMilton(data.milton.address);
        await data.joseph
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                derivativeParams.asset,
                USD_14_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(derivativeParams);
        let derivativeItem = await testData.miltonStorage.getSwapPayFixedItem(
            1
        );
        let closePositionTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await data.iporConfiguration.setMilton(miltonStorageAddress.address);

        //when
        await assertError(
            testData.miltonStorage
                .connect(userThree)
                .updateStorageWhenCloseSwapPayFixed(
                    userTwo.address,
                    derivativeItem,
                    BigInt("10000000000000000000"),
                    closePositionTimestamp
                ),
            //then
            "IPOR_1"
        );
    });

    const openSwapPayFixed = async (params) => {
        await data.milton
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );
    };

    const openSwapReceiveFixed = async (params) => {
        await data.milton
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.asset,
                params.totalAmount,
                params.slippageValue,
                params.collateralizationFactor
            );
    };

    const preprareSwapPayFixedStruct18DecSimpleCase1 = async (testData) => {
        let openingTimestamp = Math.floor(Date.now() / 1000);
        let closePositionTimestamp =
            openingTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        return {
            state: 0,
            buyer: userTwo.address,
            asset: testData.tokenDai.address,
            startingTimestamp: openingTimestamp,
            endingTimestamp: closePositionTimestamp,
            id: 1,
            collateral: BigInt("1000000000000000000000"),
            liquidationDepositAmount: BigInt("20000000000000000000"),
            notionalAmount: BigInt("50000000000000000000000"),
            ibtQuantity: 123,
            fixedInterestRate: 234,
        };
    };
});
