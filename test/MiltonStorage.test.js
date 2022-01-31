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
    USD_28_000_18DEC,
    USD_14_000_6DEC,
    USD_28_000_6DEC,
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

        await testData.iporAssetConfigurationDai.setMilton(
            miltonStorageAddress.address
        );

        //when
        await testData.miltonStorageDai
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
            testData.miltonStorageDai
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

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);
        let derivativeItem = await testData.miltonStorageDai.getSwapPayFixed(1);
        let closeSwapTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.iporAssetConfigurationDai.setMilton(
            miltonStorageAddress.address
        );

        //when
        testData.miltonStorageDai
            .connect(miltonStorageAddress)
            .updateStorageWhenCloseSwapPayFixed(
                userTwo.address,
                derivativeItem,
                BigInt("10000000000000000000"),
                closeSwapTimestamp
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

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_6DEC,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);
        let derivativeItem = await testData.miltonStorageUsdt.getSwapPayFixed(
            1
        );
        let closeSwapTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.iporAssetConfigurationUsdt.setMilton(
            miltonStorageAddress.address
        );

        //when
        testData.miltonStorageUsdt
            .connect(miltonStorageAddress)
            .updateStorageWhenCloseSwapPayFixed(
                userTwo.address,
                derivativeItem,
                BigInt("10000000"),
                closeSwapTimestamp
            );
        //then
        //assert(true); //no exception this line is achieved
    });

    it("should NOT update Milton Storage when close position, caller don't have rights to update", async () => {
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

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(
                USD_28_000_18DEC,
                derivativeParams.openTimestamp
            );

        await openSwapPayFixed(testData, derivativeParams);
        let derivativeItem = await testData.miltonStorageDai.getSwapPayFixed(1);
        let closeSwapTimestamp =
            derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await testData.iporAssetConfigurationDai.setMilton(
            miltonStorageAddress.address
        );

        //when
        await assertError(
            testData.miltonStorageDai
                .connect(userThree)
                .updateStorageWhenCloseSwapPayFixed(
                    userTwo.address,
                    derivativeItem,
                    BigInt("10000000000000000000"),
                    closeSwapTimestamp
                ),
            //then
            "IPOR_1"
        );
    });

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

    const openSwapReceiveFixed = async (testData, params) => {
        if (params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (params.asset === testData.tokenDai.address) {
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

    const preprareSwapPayFixedStruct18DecSimpleCase1 = async (testData) => {
        let openingTimestamp = Math.floor(Date.now() / 1000);
        let closeSwapTimestamp = openingTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        return {
            state: 0,
            buyer: userTwo.address,
            startingTimestamp: openingTimestamp,
            endingTimestamp: closeSwapTimestamp,
            id: 1,
            collateral: BigInt("1000000000000000000000"),
            liquidationDepositAmount: BigInt("20000000000000000000"),
            notionalAmount: BigInt("50000000000000000000000"),
            ibtQuantity: 123,
            fixedInterestRate: 234,
        };
    };
});
