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
    TC_TOTAL_AMOUNT_100_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
    USD_28_000_18DEC,
    USD_28_000_6DEC,
    USD_50_000_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    setupTokenUsdtInitialValuesForUsers,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdcInitialValuesForUsers, assertError,
} = require("./Utils");
const {TC_TOTAL_AMOUNT_10_18DEC} = require("./Const");

describe("MiltonFrontendDataProvider", () => {
    let data = null;
    let admin,
        userOne,
        userTwo,
        userThree,
        liquidityProvider,
        miltonStorageAddress;

    before(async () => {
        [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
            miltonStorageAddress,
        ] = await ethers.getSigners();
        data = await prepareData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            1
        );
    });

    it("should list correct number DAI, USDC, USDT items", async () => {
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
            ["DAI", "USDC", "USDT"],
            data,
            0,
            1
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

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDC",
            data,
            testData
        );
        await setupTokenUsdcInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            testData
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

        const paramsDai = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        const paramsUsdt = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        const paramsUsdc = {
            asset: testData.tokenUsdc.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                paramsDai.asset,
                PERCENTAGE_5_18DEC,
                paramsDai.openTimestamp
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                paramsUsdc.asset,
                PERCENTAGE_5_18DEC,
                paramsUsdc.openTimestamp
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                paramsUsdt.asset,
                PERCENTAGE_5_18DEC,
                paramsUsdt.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, paramsDai.openTimestamp);

        await testData.josephUsdc
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdc.openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdt.openTimestamp);

        const expectedSwapsLength = 3;

        const MiltonFrontendDataProvider = await ethers.getContractFactory(
            "MiltonFrontendDataProvider"
        );
        const miltonFrontendDataProvider =
            await MiltonFrontendDataProvider.deploy();
        await miltonFrontendDataProvider.deployed();
        await miltonFrontendDataProvider.initialize(
            data.iporConfiguration.address,
            testData.warren.address,
            testData.miltonDai.address,
            testData.miltonUsdt.address,
            testData.miltonUsdc.address
        );

        //when
        await openSwapPayFixed(testData, paramsDai);
        await openSwapPayFixed(testData, paramsUsdc);
        await openSwapPayFixed(testData, paramsUsdt);

        let responseDai = await miltonFrontendDataProvider
            .connect(paramsDai.from)
            .getMySwaps(paramsDai.asset, 0, 50);
        let itemsDai = responseDai.swaps;

        let responseUsdc = await miltonFrontendDataProvider
            .connect(paramsUsdc.from)
            .getMySwaps(paramsUsdc.asset, 0, 50);
        let itemsUsdc = responseUsdc.swaps;

        let responseUsdt = await miltonFrontendDataProvider
            .connect(paramsUsdt.from)
            .getMySwaps(paramsUsdt.asset, 0, 50);
        let itemsUsdt = responseUsdt.swaps;

        const actualDaiSwapsLength = itemsDai.length;
        const actualUsdcSwapsLength = itemsUsdc.length;
        const actualUsdtSwapsLength = itemsUsdt.length;
        const actualSwapsLength =
            actualDaiSwapsLength +
            actualUsdcSwapsLength +
            actualUsdtSwapsLength;

        //then
        expect(expectedSwapsLength).to.be.eq(actualSwapsLength);
    });

    it("should fail when page size is equal 0", async () => {
        await testCasePagination(0, 0, 0, 0, 'IPOR_63');
    });

    it("should receive empty list of swaps", async () => {
        await testCasePagination(0, 0, 10, 0, null);
    });

    it("should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCasePagination(0, 10, 10, 0, null);
    });

    it("should receive limited swap array", async () => {
        await testCasePagination(11, 0, 10, 10, null);
    });

    it("should receive limited swap array with offset", async () => {
        await testCasePagination(22, 10, 10, 10, null);
    });

    it("should receive rest of swaps only", async () => {
        await testCasePagination(22, 20, 10, 2, null);
    });

    it("should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCasePagination(20, 20, 10, 0, null);
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

    const testCasePagination = async (numberOfSwapsToCreate, offset, pageSize, expectedResponseSize, expectedError) => {
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
            ["DAI", "USDC", "USDT"],
            data,
            0,
            1
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

        const paramsDai = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_100_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                paramsDai.asset,
                PERCENTAGE_5_18DEC,
                paramsDai.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, paramsDai.openTimestamp);

        const MiltonFrontendDataProvider = await ethers.getContractFactory(
            "MiltonFrontendDataProvider"
        );
        const miltonFrontendDataProvider =
            await MiltonFrontendDataProvider.deploy();
        await miltonFrontendDataProvider.deployed();
        await miltonFrontendDataProvider.initialize(
            data.iporConfiguration.address,
            testData.warren.address,
            testData.miltonDai.address,
            testData.miltonUsdt.address,
            testData.miltonUsdc.address
        );

        for (let i = 0; i < numberOfSwapsToCreate; i++) {
            if (i % 2 === 0) {
                await openSwapPayFixed(testData, paramsDai);
            } else {
                await openSwapReceiveFixed(testData, paramsDai);
            }
        }

        //when
        if (expectedError == null) {
            let response = await miltonFrontendDataProvider
                .connect(paramsDai.from)
                .getMySwaps(paramsDai.asset, offset, pageSize);

            const actualSwapsLength = response.swaps.length;
            const totalSwapCount = response.totalCount

            //then
            expect(actualSwapsLength).to.be.eq(expectedResponseSize);
            expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
        } else {
            await assertError(
                miltonFrontendDataProvider
                    .connect(paramsDai.from)
                    .getMySwaps(paramsDai.asset, offset, pageSize),
                expectedError
            );
        }
    }
});
