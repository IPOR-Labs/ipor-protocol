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
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_14_000_18DEC,
    USD_28_000_18DEC,
    USD_14_000_6DEC,
    USD_28_000_6DEC,
    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    assertError,
    setupTokenUsdtInitialValuesForUsers,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
    setupDefaultSpreadConstants,
} = require("./Utils");

describe("MiltonStorage", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] =
            await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1,0
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonStorageDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.miltonStorageDai.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await testData.miltonStorageDai.connect(userOne).owner();
        expect(expectedNewOwner.address).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1,0
        );
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            testData.miltonStorageDai
                .connect(userThree)
                .transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1,0
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonStorageDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await assertError(
            testData.miltonStorageDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1,0
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.miltonStorageDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.miltonStorageDai.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            testData.miltonStorageDai.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1,0
        );
        const expectedNewOwner = userTwo;

        await testData.miltonStorageDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.miltonStorageDai.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            testData.miltonStorageDai.connect(admin).transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1,0
        );
        const expectedNewOwner = userTwo;

        await testData.miltonStorageDai.connect(admin).transferOwnership(expectedNewOwner.address);

        //when
        await testData.miltonStorageDai.connect(admin).transferOwnership(expectedNewOwner.address);

        //then
        const actualNewOwner = await testData.miltonStorageDai.connect(userOne).owner();
        expect(admin.address).to.be.eql(actualNewOwner);
    });

    it("should update Milton Storage when open position, caller has rights to update", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            data,
            0,
            1,0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers([admin, userOne, liquidityProvider], testData);

        await testData.miltonStorageDai.setMilton(miltonStorageAddress.address);

        //when
        await testData.miltonStorageDai
            .connect(miltonStorageAddress)
            .updateStorageWhenOpenSwapPayFixed(
                await preprareSwapPayFixedStruct18DecSimpleCase1(testData),
                BigInt("1500000000000000000000"),
                await testData.miltonDai.getLiquidationDepositAmount(),
                await testData.miltonDai.getIporPublicationFeeAmount(),
                await testData.miltonDai.getOpeningFeeForTreasuryPercentage()
            );
        //then
        //assert(true); //no exception this line is achieved
    });

    it("should NOT update Milton Storage when open position, caller dont have rights to update", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            data,
            0,
            1,0
        );
        const derivativeStruct = await preprareSwapPayFixedStruct18DecSimpleCase1(testData);
        await assertError(
            //when
            testData.miltonStorageDai
                .connect(userThree)
                .updateStorageWhenOpenSwapPayFixed(
                    derivativeStruct,
                    BigInt("1500000000000000000000"),
                    await testData.miltonDai.getLiquidationDepositAmount(),
                    await testData.miltonDai.getIporPublicationFeeAmount(),
                    await testData.miltonDai.getOpeningFeeForTreasuryPercentage()
                ),
            //then
            "IPOR_008"
        );
    });

    it("should update Milton Storage when close position, caller has rights to update, DAI 18 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            data,
            0,
            1,0
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
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
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
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);

        await openSwapPayFixed(testData, derivativeParams);
        let derivativeItem = await testData.miltonStorageDai.getSwapPayFixed(1);
        let closeSwapTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.miltonStorageDai.setMilton(miltonStorageAddress.address);

        //when
        await testData.miltonStorageDai
            .connect(miltonStorageAddress)
            .updateStorageWhenCloseSwapPayFixed(
                userTwo.address,
                derivativeItem,
                BigInt("10000000000000000000"),
                closeSwapTimestamp,
                await testData.miltonDai.getIncomeTaxPercentage()
            );

        await testData.miltonStorageDai.setMilton(testData.miltonDai.address);

        //then
        // assert(true); //no exception this line is achieved
    });

    it("should update Milton Storage when close position, caller has rights to update, USDT 6 decimals", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["USDT"],
            data,
            0,
            1,0
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
            toleratedQuoteValue: BigInt("900000000000000000"),
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
            .itfProvideLiquidity(USD_28_000_6DEC, derivativeParams.openTimestamp);

        await openSwapPayFixed(testData, derivativeParams);
        let derivativeItem = await testData.miltonStorageUsdt.getSwapPayFixed(1);
        let closeSwapTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await testData.miltonStorageUsdt.setMilton(miltonStorageAddress.address);

        //when
        await testData.miltonStorageUsdt
            .connect(miltonStorageAddress)
            .updateStorageWhenCloseSwapPayFixed(
                userTwo.address,
                derivativeItem,
                BigInt("10000000"),
                closeSwapTimestamp,
                await testData.miltonUsdt.getIncomeTaxPercentage()
            );
        //then
        //assert(true); //no exception this line is achieved
    });

    it("should NOT update Milton Storage when close position, caller don't have rights to update", async () => {
        // given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            data,
            0,
            1,0
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
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
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
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);

        await openSwapPayFixed(testData, derivativeParams);
        let derivativeItem = await testData.miltonStorageDai.getSwapPayFixed(1);
        let closeSwapTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await assertError(
            testData.miltonStorageDai
                .connect(userThree)
                .updateStorageWhenCloseSwapPayFixed(
                    userTwo.address,
                    derivativeItem,
                    BigInt("10000000000000000000"),
                    closeSwapTimestamp,
                    await testData.miltonDai.getIncomeTaxPercentage()
                ),
            //then
            "IPOR_008"
        );
    });

    const openSwapPayFixed = async (testData, params) => {
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.collateralizationFactor
                );
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.collateralizationFactor
                );
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
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
                    params.toleratedQuoteValue,
                    params.collateralizationFactor
                );
        }

        if (params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.collateralizationFactor
                );
        }

        if (params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
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
