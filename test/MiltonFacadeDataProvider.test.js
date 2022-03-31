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
    setupTokenUsdcInitialValuesForUsers,
    assertError,
} = require("./Utils");
const { TC_TOTAL_AMOUNT_10_18DEC } = require("./Const");

describe("MiltonFacadeDataProvider", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] =
            await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });

    it("should list configuration DAI, USDC, USDT", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI", "USDC", "USDT"],
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
            maxAcceptableFixedInterestRate: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        const paramsUsdt = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            maxAcceptableFixedInterestRate: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        const paramsUsdc = {
            asset: testData.tokenUsdc.address,
            totalAmount: USD_10_000_6DEC,
            maxAcceptableFixedInterestRate: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsDai.asset, PERCENTAGE_5_18DEC, paramsDai.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsUsdc.asset, PERCENTAGE_5_18DEC, paramsUsdc.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsUsdt.asset, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, paramsDai.openTimestamp);

        await testData.josephUsdc
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdc.openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdt.openTimestamp);

        const MiltonFacadeDataProvider = await ethers.getContractFactory(
            "MiltonFacadeDataProvider"
        );
        const miltonFacadeDataProvider = await MiltonFacadeDataProvider.deploy();
        await miltonFacadeDataProvider.deployed();
        await miltonFacadeDataProvider.initialize(
            testData.warren.address,
            [testData.tokenDai.address, testData.tokenUsdt.address, testData.tokenUsdc.address],
            [testData.miltonDai.address, testData.miltonUsdt.address, testData.miltonUsdc.address],
            [
                testData.miltonStorageDai.address,
                testData.miltonStorageUsdt.address,
                testData.miltonStorageUsdc.address,
            ],
            [testData.josephDai.address, testData.josephUsdt.address, testData.josephUsdc.address]
        );

        const expectedMinLeverage = BigInt("10000000000000000000");
        const expectedMaxLeverage = BigInt("1000000000000000000000");
        const expectedOpeningFeePercentage = BigInt("10000000000000000");
        const expectedIporPublicationFeeAmount = BigInt("10000000000000000000");
        const expectedLiquidationDepositAmount = BigInt("20000000000000000000");
        const expectedIncomeFeePercentage = BigInt("100000000000000000");
        const expectedSpreadPayFixedValue = BigInt("10000000000000000");
        const expectedSpreadRecFixedValue = BigInt("10000000000000000");
        const expectedMaxLpUtilizationPercentage = BigInt("800000000000000000");
        const expectedMaxLpUtilizationPerLegPercentage = BigInt("480000000000000000");

        //when
        const configs = await miltonFacadeDataProvider.getConfiguration();

        //then

        for (let i = 0; i < configs.length; i++) {
            expect(expectedMinLeverage).to.be.eq(configs[i].minLeverage);
            expect(expectedMaxLeverage).to.be.eq(configs[i].maxLeverage);
            expect(expectedOpeningFeePercentage).to.be.eq(configs[i].openingFeeRate);
            expect(expectedIporPublicationFeeAmount).to.be.eq(configs[i].iporPublicationFeeAmount);
            expect(expectedLiquidationDepositAmount).to.be.eq(configs[i].liquidationDepositAmount);
            expect(expectedIncomeFeePercentage).to.be.eq(configs[i].incomeFeeRate);
            expect(expectedSpreadPayFixedValue).to.be.eq(configs[i].spreadPayFixed);
            expect(expectedSpreadRecFixedValue).to.be.eq(configs[i].spreadReceiveFixed);
            expect(expectedMaxLpUtilizationPercentage).to.be.eq(configs[i].maxLpUtilizationRate);
            expect(expectedMaxLpUtilizationPerLegPercentage).to.be.eq(
                configs[i].maxLpUtilizationPerLegRate
            );
        }
    });

    it("should list correct number DAI, USDC, USDT items", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI", "USDC", "USDT"],
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
            maxAcceptableFixedInterestRate: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        const paramsUsdt = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            maxAcceptableFixedInterestRate: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        const paramsUsdc = {
            asset: testData.tokenUsdc.address,
            totalAmount: USD_10_000_6DEC,
            maxAcceptableFixedInterestRate: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsDai.asset, PERCENTAGE_5_18DEC, paramsDai.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsUsdc.asset, PERCENTAGE_5_18DEC, paramsUsdc.openTimestamp);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsUsdt.asset, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

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

        const MiltonFacadeDataProvider = await ethers.getContractFactory(
            "MiltonFacadeDataProvider"
        );
        const miltonFacadeDataProvider = await MiltonFacadeDataProvider.deploy();
        await miltonFacadeDataProvider.deployed();

        await miltonFacadeDataProvider.initialize(
            testData.warren.address,
            [testData.tokenDai.address, testData.tokenUsdt.address, testData.tokenUsdc.address],
            [testData.miltonDai.address, testData.miltonUsdt.address, testData.miltonUsdc.address],
            [
                testData.miltonStorageDai.address,
                testData.miltonStorageUsdt.address,
                testData.miltonStorageUsdc.address,
            ],
            [testData.josephDai.address, testData.josephUsdt.address, testData.josephUsdc.address]
        );

        //when
        await openSwapPayFixed(testData, paramsDai);
        await openSwapPayFixed(testData, paramsUsdc);
        await openSwapPayFixed(testData, paramsUsdt);

        const responseDai = await miltonFacadeDataProvider
            .connect(paramsDai.from)
            .getMySwaps(paramsDai.asset, 0, 50);
        const itemsDai = responseDai.swaps;

        const responseUsdc = await miltonFacadeDataProvider
            .connect(paramsUsdc.from)
            .getMySwaps(paramsUsdc.asset, 0, 50);
        const itemsUsdc = responseUsdc.swaps;

        const responseUsdt = await miltonFacadeDataProvider
            .connect(paramsUsdt.from)
            .getMySwaps(paramsUsdt.asset, 0, 50);
        const itemsUsdt = responseUsdt.swaps;

        const actualDaiSwapsLength = itemsDai.length;
        const actualUsdcSwapsLength = itemsUsdc.length;
        const actualUsdtSwapsLength = itemsUsdt.length;
        const actualSwapsLength =
            actualDaiSwapsLength + actualUsdcSwapsLength + actualUsdtSwapsLength;

        //then
        expect(expectedSwapsLength).to.be.eq(actualSwapsLength);
    });

    it("should fail when page size is equal 0", async () => {
        await testCasePagination(0, 0, 0, 0, "IPOR_009");
    });

    it("should fail when page size is greater than 50", async () => {
        await testCasePagination(0, 0, 51, 0, "IPOR_010");
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
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                );
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                );
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
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
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                );
        }

        if (params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                );
        }

        if (params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
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
            notional: BigInt("50000000000000000000000"),
            ibtQuantity: 123,
            fixedInterestRate: 234,
        };
    };

    const testCasePagination = async (
        numberOfSwapsToCreate,
        offset,
        pageSize,
        expectedResponseSize,
        expectedError
    ) => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI", "USDC", "USDT"],
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

        const paramsDai = {
            asset: testData.tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_100_18DEC,
            maxAcceptableFixedInterestRate: BigInt("900000000000000000"),
            leverage: LEVERAGE_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(paramsDai.asset, PERCENTAGE_5_18DEC, paramsDai.openTimestamp);

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, paramsDai.openTimestamp);

        const MiltonFacadeDataProvider = await ethers.getContractFactory(
            "MiltonFacadeDataProvider"
        );
        const miltonFacadeDataProvider = await MiltonFacadeDataProvider.deploy();
        await miltonFacadeDataProvider.deployed();
        await miltonFacadeDataProvider.initialize(
            testData.warren.address,
            [testData.tokenDai.address, testData.tokenUsdt.address, testData.tokenUsdc.address],
            [testData.miltonDai.address, testData.miltonUsdt.address, testData.miltonUsdc.address],
            [
                testData.miltonStorageDai.address,
                testData.miltonStorageUsdt.address,
                testData.miltonStorageUsdc.address,
            ],
            [testData.josephDai.address, testData.josephUsdt.address, testData.josephUsdc.address]
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
            const response = await miltonFacadeDataProvider
                .connect(paramsDai.from)
                .getMySwaps(paramsDai.asset, offset, pageSize);

            const actualSwapsLength = response.swaps.length;
            const totalSwapCount = response.totalCount;

            //then
            expect(actualSwapsLength).to.be.eq(expectedResponseSize);
            expect(totalSwapCount).to.be.eq(numberOfSwapsToCreate);
        } else {
            await assertError(
                miltonFacadeDataProvider
                    .connect(paramsDai.from)
                    .getMySwaps(paramsDai.asset, offset, pageSize),
                expectedError
            );
        }
    };
});
