const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    LEVERAGE_6DEC,
    LEVERAGE_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_3_6DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_95_18DEC,
    TC_TOTAL_AMOUNT_100_6DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_14_000_18DEC,
    USD_28_000_18DEC,
    USD_14_000_6DEC,
    USD_28_000_6DEC,
    USD_50_000_6DEC,
    PERIOD_6_HOURS_IN_SECONDS,
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
            1,
            0
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
            1,
            0
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
            1,
            0
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
            1,
            0
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
            1,
            0
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
            1,
            0
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
            1,
            0
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
                await testData.miltonDai.getIporPublicationFeeAmount()
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
            1,
            0
        );
        const derivativeStruct = await preprareSwapPayFixedStruct18DecSimpleCase1(testData);
        await assertError(
            //when
            testData.miltonStorageDai
                .connect(userThree)
                .updateStorageWhenOpenSwapPayFixed(
                    derivativeStruct,
                    await testData.miltonDai.getIporPublicationFeeAmount()
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
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
                await testData.miltonDai.getIncomeFeePercentage(),
                PERCENTAGE_95_18DEC,
                PERIOD_6_HOURS_IN_SECONDS
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const derivativeParams = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
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
                await testData.miltonUsdt.getIncomeFeePercentage(),
                PERCENTAGE_95_18DEC,
                PERIOD_6_HOURS_IN_SECONDS
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );
        const derivativeParams = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
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
                    await testData.miltonDai.getIncomeFeePercentage(),
                    PERCENTAGE_95_18DEC,
                    PERIOD_6_HOURS_IN_SECONDS
                ),
            //then
            "IPOR_008"
        );
    });

    it("get swaps - pay fixed, should fail when page size is equal 0", async () => {
        await testCasePaginationPayFixed(0, 0, 0, 0, "IPOR_009");
    });

    it("get swaps - pay fixed, should return empty list of swaps", async () => {
        await testCasePaginationPayFixed(0, 0, 10, 0, null);
    });

    it("get swaps - pay fixed, should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCasePaginationPayFixed(0, 10, 10, 0, null);
    });

    it("get swaps - pay fixed, should receive limited swap array", async () => {
        await testCasePaginationPayFixed(11, 0, 10, 10, null);
    });

    it("get swaps - pay fixed, should receive limited swap array with offset", async () => {
        await testCasePaginationPayFixed(22, 10, 10, 10, null);
    });

    it("get swaps - pay fixed, should receive rest of swaps only", async () => {
        await testCasePaginationPayFixed(22, 20, 10, 2, null);
    });

    it("get swaps - pay fixed, should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCasePaginationPayFixed(20, 20, 10, 0, null);
    });

    it("get swaps - receive fixed, should fail when page size is equal 0", async () => {
        await testCasePaginationReceiveFixed(0, 0, 0, 0, "IPOR_009");
    });

    it("get swaps - receive fixed, should return empty list of swaps", async () => {
        await testCasePaginationReceiveFixed(0, 0, 10, 0, null);
    });

    it("get swaps - receive fixed, should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCasePaginationReceiveFixed(0, 10, 10, 0, null);
    });

    it("get swaps - receive fixed, should receive limited swap array", async () => {
        await testCasePaginationReceiveFixed(11, 0, 10, 10, null);
    });

    it("get swaps - receive fixed, should receive limited swap array with offset", async () => {
        await testCasePaginationReceiveFixed(22, 10, 10, 10, null);
    });

    it("get swaps - receive fixed, should receive rest of swaps only", async () => {
        await testCasePaginationReceiveFixed(22, 20, 10, 2, null);
    });

    it("get swaps - receive fixed, should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCasePaginationReceiveFixed(20, 20, 10, 0, null);
    });

    it("get swap ids - pay fixed, should fail when page size is equal 0", async () => {
        await testCaseIdsPaginationPayFixed(0, 0, 0, 0, "IPOR_009");
    });

    it("get swap ids - pay fixed, should return empty list of swaps", async () => {
        await testCaseIdsPaginationPayFixed(0, 0, 10, 0, null);
    });

    it("get swap ids - pay fixed, should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCaseIdsPaginationPayFixed(0, 10, 10, 0, null);
    });

    it("get swap ids - pay fixed, should receive limited swap array", async () => {
        await testCaseIdsPaginationPayFixed(11, 0, 10, 10, null);
    });

    it("get swap ids - pay fixed, should receive limited swap array with offset", async () => {
        await testCaseIdsPaginationPayFixed(22, 10, 10, 10, null);
    });

    it("get swap ids - pay fixed, should receive rest of swaps only", async () => {
        await testCaseIdsPaginationPayFixed(22, 20, 10, 2, null);
    });

    it("get swap ids - pay fixed, should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCaseIdsPaginationPayFixed(20, 20, 10, 0, null);
    });

    it("get swap ids - receive fixed, should fail when page size is equal 0", async () => {
        await testCaseIdsPaginationReceiveFixed(0, 0, 0, 0, "IPOR_009");
    });

    it("get swap ids - receive fixed, should return empty list of swaps", async () => {
        await testCaseIdsPaginationReceiveFixed(0, 0, 10, 0, null);
    });

    it("get swap ids - receive fixed, should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCaseIdsPaginationReceiveFixed(0, 10, 10, 0, null);
    });

    it("get swap ids - receive fixed, should receive limited swap array", async () => {
        await testCaseIdsPaginationReceiveFixed(11, 0, 10, 10, null);
    });

    it("get swap ids - receive fixed, should receive limited swap array with offset", async () => {
        await testCaseIdsPaginationReceiveFixed(22, 10, 10, 10, null);
    });

    it("get swap ids - receive fixed, should receive rest of swaps only", async () => {
        await testCaseIdsPaginationReceiveFixed(22, 20, 10, 2, null);
    });

    it("get swap ids - receive fixed, should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCaseIdsPaginationReceiveFixed(20, 20, 10, 0, null);
    });

    it("get swap ids - all, should fail when page size is equal 0", async () => {
        await testCaseIdsPagination(0, 0, 0, 0, 0, "IPOR_009");
    });

    it("get swap ids - all, should receive empty list of swap ids", async () => {
        await testCaseIdsPagination(0, 0, 0, 10, 0, null);
    });

    it("get swap ids - all, should receive empty list of swap ids when user passes non zero offset and doesn't have any swap", async () => {
        await testCaseIdsPagination(0, 0, 10, 10, 0, null);
    });

    it("get swap ids - all, should return pay fixed swaps if user doesn't have receive fixed swaps", async () => {
        await testCaseIdsPagination(5, 0, 0, 10, 5, null);
    });

    it("get swap ids - all, should return receive fixed swaps if user doesn't have pay fixed swaps", async () => {
        await testCaseIdsPagination(0, 5, 0, 10, 5, null);
    });

    it("get swap ids - all, should return all swaps", async () => {
        await testCaseIdsPagination(3, 3, 0, 10, 6, null);
    });

    it("get swap ids - all, should return limited swap id array if user has more swaps than page size", async () => {
        await testCaseIdsPagination(9, 12, 0, 10, 10, null);
    });

    it("get swap ids - all, should return empty array when offset is higher than total number of user swaps", async () => {
        await testCaseIdsPagination(9, 12, 80, 10, 0, null);
    });

    const testCasePaginationPayFixed = async (
        numberOfSwapsToCreate,
        offset,
        pageSize,
        expectedResponseSize,
        expectedError
    ) => {
        // given
        const testData = await preparePayFixedState(numberOfSwapsToCreate);

        //when
        if (expectedError == null) {
            const response = await testData.miltonStorageUsdt.getSwapsPayFixed(
                userTwo.address,
                offset,
                pageSize
            );

            const actualSwapsLength = response.swaps.length;
            const totalSwapCount = response.totalCount;

            //then
            expect(actualSwapsLength).to.be.eq(expectedResponseSize);
            expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
        } else {
            await assertError(
                testData.miltonStorageUsdt.getSwapsPayFixed(userTwo.address, offset, pageSize),
                expectedError
            );
        }
    };

    const testCasePaginationReceiveFixed = async (
        numberOfSwapsToCreate,
        offset,
        pageSize,
        expectedResponseSize,
        expectedError
    ) => {
        // given
        const testData = await prepareReceiveFixedState(numberOfSwapsToCreate);

        //when
        if (expectedError == null) {
            const response = await testData.miltonStorageUsdt.getSwapsReceiveFixed(
                userTwo.address,
                offset,
                pageSize
            );

            const actualSwapsLength = response.swaps.length;
            const totalSwapCount = response.totalCount;

            //then
            expect(actualSwapsLength).to.be.eq(expectedResponseSize);
            expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
        } else {
            await assertError(
                testData.miltonStorageUsdt.getSwapsReceiveFixed(userTwo.address, offset, pageSize),
                expectedError
            );
        }
    };

    const testCaseIdsPaginationPayFixed = async (
        numberOfSwapsToCreate,
        offset,
        pageSize,
        expectedResponseSize,
        expectedError
    ) => {
        // given
        const testData = await preparePayFixedState(numberOfSwapsToCreate);

        //when
        if (expectedError == null) {
            const response = await testData.miltonStorageUsdt.getSwapPayFixedIds(
                userTwo.address,
                offset,
                pageSize
            );

            const actualSwapsLength = response.ids.length;
            const totalSwapCount = response.totalCount;

            //then
            expect(actualSwapsLength).to.be.eq(expectedResponseSize);
            expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
        } else {
            await assertError(
                testData.miltonStorageUsdt.getSwapsPayFixed(userTwo.address, offset, pageSize),
                expectedError
            );
        }
    };

    const testCaseIdsPaginationReceiveFixed = async (
        numberOfSwapsToCreate,
        offset,
        pageSize,
        expectedResponseSize,
        expectedError
    ) => {
        // given
        const testData = await prepareReceiveFixedState(numberOfSwapsToCreate);

        //when
        if (expectedError == null) {
            const response = await testData.miltonStorageUsdt.getSwapReceiveFixedIds(
                userTwo.address,
                offset,
                pageSize
            );

            const actualSwapsLength = response.ids.length;
            const totalSwapCount = response.totalCount;

            //then
            expect(actualSwapsLength).to.be.eq(expectedResponseSize);
            expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
        } else {
            await assertError(
                testData.miltonStorageUsdt.getSwapsReceiveFixed(userTwo.address, offset, pageSize),
                expectedError
            );
        }
    };

    const testCaseIdsPagination = async (
        numberOfPayFixedSwapsToCreate,
        numberOfReceiveFixedSwapsToCreate,
        offset,
        pageSize,
        expectedResponseSize,
        expectedError
    ) => {
        // given
        const testData = await prepareState(
            numberOfPayFixedSwapsToCreate,
            numberOfReceiveFixedSwapsToCreate
        );

        //when
        if (expectedError == null) {
            const response = await testData.miltonStorageUsdt.getSwapIds(
                userTwo.address,
                offset,
                pageSize
            );

            const actualSwapsLength = response.ids.length;
            const totalSwapCount = response.totalCount;

            //then
            expect(actualSwapsLength).to.be.eq(expectedResponseSize);
            expect(totalSwapCount).to.be.eq(
                numberOfPayFixedSwapsToCreate + numberOfReceiveFixedSwapsToCreate
            );
        } else {
            await assertError(
                testData.miltonStorageUsdt.getSwapsReceiveFixed(userTwo.address, offset, pageSize),
                expectedError
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

    const openSwapReceiveFixed = async (testData, params) => {
        if (params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                );
        }

        if (params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.toleratedQuoteValue,
                    params.leverage
                );
        }

        if (params.asset === testData.tokenDai.address) {
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

    const preprareSwapPayFixedStruct18DecSimpleCase1 = async (testData) => {
        let openingTimestamp = Math.floor(Date.now() / 1000);
        let closeSwapTimestamp = openingTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        return {
            state: 0,
            buyer: userTwo.address,
            openTimestamp: openingTimestamp,
            endTimestamp: closeSwapTimestamp,
            id: 1,
            collateral: BigInt("1000000000000000000000"),
            liquidationDepositAmount: BigInt("20000000000000000000"),
            notionalAmount: BigInt("50000000000000000000000"),
            fixedInterestRate: 234,
            ibtQuantity: 123,
            openingFeeLPAmount: BigInt("1500000000000000000000"),
			openingFeeTreasuryAmount: BigInt("1500000000000000000000")
        };
    };

    const preparePayFixedState = async (numberOfSwapsToCreate) => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const paramsUsdt = {
            asset: testData.tokenUsdt.address,
            totalAmount: TC_TOTAL_AMOUNT_100_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsUsdt.asset, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_6DEC, paramsUsdt.openTimestamp);

        for (let i = 0; i < numberOfSwapsToCreate; i++) {
            await openSwapPayFixed(testData, paramsUsdt);
        }

        return testData;
    };

    const prepareReceiveFixedState = async (numberOfSwapsToCreate) => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["USDT", "USDC", "DAI"],
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const paramsUsdt = {
            asset: testData.tokenUsdt.address,
            totalAmount: TC_TOTAL_AMOUNT_100_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsUsdt.asset, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_6DEC, paramsUsdt.openTimestamp);

        for (let i = 0; i < numberOfSwapsToCreate; i++) {
            await openSwapReceiveFixed(testData, paramsUsdt);
        }

        return testData;
    };

    const prepareState = async (
        numberOfPayFixedSwapsToCreate,
        numberOfReceiveFixedSwapsToCreate
    ) => {
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["USDT", "USDC", "DAI"],
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
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const paramsUsdt = {
            asset: testData.tokenUsdt.address,
            totalAmount: TC_TOTAL_AMOUNT_100_6DEC,
            toleratedQuoteValue: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsUsdt.asset, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_6DEC, paramsUsdt.openTimestamp);

        for (let i = 0; i < numberOfPayFixedSwapsToCreate; i++) {
            await openSwapPayFixed(testData, paramsUsdt);
        }
        for (let i = 0; i < numberOfReceiveFixedSwapsToCreate; i++) {
            await openSwapReceiveFixed(testData, paramsUsdt);
        }

        return testData;
    };
});
