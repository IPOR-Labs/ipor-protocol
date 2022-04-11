import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    ZERO,
    N0__1_18DEC,
    N0__01_18DEC,
    N0__000_1_18DEC,
    N1__0_18DEC,
    PERCENTAGE_5_18DEC,
    USD_28_000_18DEC,
    LEVERAGE_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_28_000_6DEC,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "../utils/MiltonUtils";
import { testCasePagination } from "../utils/AssertUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
    setupTokenUsdcInitialValuesForUsers,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";
import { openSwapPayFixed } from "../utils/SwapUtils";

const { expect } = chai;

describe("MiltonFacadeDataProvider", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer,
        miltonStorageAddress: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] =
            await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should list configuration DAI, USDC, USDT", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI", "USDC", "USDT"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const {
            tokenUsdc,
            tokenUsdt,
            tokenDai,
            iporOracle,
            josephDai,
            josephUsdc,
            josephUsdt,
            miltonUsdt,
            miltonUsdc,
            miltonDai,
            miltonStorageUsdt,
            miltonStorageUsdc,
            miltonStorageDai,
        } = testData;

        if (
            tokenUsdc === undefined ||
            tokenUsdt === undefined ||
            tokenDai === undefined ||
            josephDai === undefined ||
            josephUsdc === undefined ||
            josephUsdt === undefined ||
            miltonDai === undefined ||
            miltonUsdt === undefined ||
            miltonUsdc === undefined ||
            miltonStorageUsdt === undefined ||
            miltonStorageUsdc === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDC",
            testData
        );
        await setupTokenUsdcInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            tokenUsdc
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            tokenUsdt
        );

        const paramsDai = {
            asset: tokenDai,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        const paramsUsdt = {
            asset: tokenUsdt,
            totalAmount: USD_10_000_6DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        const paramsUsdc = {
            asset: tokenUsdc,
            totalAmount: USD_10_000_6DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsDai.asset.address, PERCENTAGE_5_18DEC, paramsDai.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsUsdc.asset.address, PERCENTAGE_5_18DEC, paramsUsdc.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsUsdt.asset.address, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, paramsDai.openTimestamp);

        await josephUsdc
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdc.openTimestamp);

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdt.openTimestamp);

        const MiltonFacadeDataProvider = await hre.ethers.getContractFactory(
            "MiltonFacadeDataProvider"
        );
        const miltonFacadeDataProvider = await MiltonFacadeDataProvider.deploy();
        await miltonFacadeDataProvider.deployed();
        await miltonFacadeDataProvider.initialize(
            iporOracle.address,
            [tokenDai.address, tokenUsdt.address, tokenUsdc.address],
            [miltonDai.address, miltonUsdt.address, miltonUsdc.address],
            [miltonStorageDai.address, miltonStorageUsdt.address, miltonStorageUsdc.address],
            [josephDai.address, josephUsdt.address, josephUsdc.address]
        );

        const expectedMinLeverage = BigNumber.from("10").mul(N1__0_18DEC);
        const expectedMaxLeverage = BigNumber.from("1000").mul(N1__0_18DEC);
        const expectedOpeningFeePercentage = BigNumber.from("3").mul(N0__000_1_18DEC);
        const expectedIporPublicationFeeAmount = BigNumber.from("10").mul(N1__0_18DEC);
        const expectedLiquidationDepositAmount = BigNumber.from("20").mul(N1__0_18DEC);
        const expectedIncomeFeeRate = BigNumber.from("1").mul(N0__1_18DEC);
        const expectedSpreadPayFixedValue = BigNumber.from("1").mul(N0__01_18DEC);
        const expectedSpreadRecFixedValue = BigNumber.from("1").mul(N0__01_18DEC);
        const expectedMaxLpUtilizationRate = BigNumber.from("8").mul(N0__1_18DEC);
        const expectedMaxLpUtilizationPerLegRate = BigNumber.from("48").mul(N0__01_18DEC);

        //when
        const configs = await miltonFacadeDataProvider.getConfiguration();

        //then

        for (let i = 0; i < configs.length; i++) {
            expect(expectedMinLeverage).to.be.eq(configs[i].minLeverage);
            expect(expectedMaxLeverage).to.be.eq(configs[i].maxLeverage);
            expect(expectedOpeningFeePercentage).to.be.equal(configs[i].openingFeeRate);
            expect(expectedIporPublicationFeeAmount).to.be.equal(
                configs[i].iporPublicationFeeAmount
            );
            expect(expectedLiquidationDepositAmount).to.be.eq(configs[i].liquidationDepositAmount);
            expect(expectedIncomeFeeRate).to.be.eq(configs[i].incomeFeeRate);
            expect(expectedSpreadPayFixedValue).to.be.eq(configs[i].spreadPayFixed);
            expect(expectedSpreadRecFixedValue).to.be.eq(configs[i].spreadReceiveFixed);
            expect(expectedMaxLpUtilizationRate).to.be.eq(configs[i].maxLpUtilizationRate);
            expect(expectedMaxLpUtilizationPerLegRate).to.be.eq(
                configs[i].maxLpUtilizationPerLegRate
            );
        }
    });

    it("should list correct number DAI, USDC, USDT items", async () => {
        //given
        const testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI", "USDC", "USDT"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const {
            tokenUsdc,
            tokenUsdt,
            tokenDai,
            iporOracle,
            josephDai,
            josephUsdc,
            josephUsdt,
            miltonUsdt,
            miltonUsdc,
            miltonDai,
            miltonStorageUsdt,
            miltonStorageUsdc,
            miltonStorageDai,
        } = testData;

        if (
            tokenUsdc === undefined ||
            tokenUsdt === undefined ||
            tokenDai === undefined ||
            josephDai === undefined ||
            josephUsdc === undefined ||
            josephUsdt === undefined ||
            miltonDai === undefined ||
            miltonUsdt === undefined ||
            miltonUsdc === undefined ||
            miltonStorageUsdt === undefined ||
            miltonStorageUsdc === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDC",
            testData
        );
        await setupTokenUsdcInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            tokenUsdc
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            tokenUsdt
        );

        const paramsDai = {
            asset: tokenDai.address,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        const paramsUsdt = {
            asset: tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        const paramsUsdc = {
            asset: tokenUsdc.address,
            totalAmount: USD_10_000_6DEC,
            maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
        };

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsDai.asset, PERCENTAGE_5_18DEC, paramsDai.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsUsdc.asset, PERCENTAGE_5_18DEC, paramsUsdc.openTimestamp);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(paramsUsdt.asset, PERCENTAGE_5_18DEC, paramsUsdt.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, paramsDai.openTimestamp);

        await josephUsdc
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdc.openTimestamp);

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdt.openTimestamp);

        const expectedSwapsLength = 3;

        const MiltonFacadeDataProvider = await hre.ethers.getContractFactory(
            "MiltonFacadeDataProvider"
        );
        const miltonFacadeDataProvider = await MiltonFacadeDataProvider.deploy();

        await miltonFacadeDataProvider.initialize(
            iporOracle.address,
            [tokenDai.address, tokenUsdt.address, tokenUsdc.address],
            [miltonDai.address, miltonUsdt.address, miltonUsdc.address],
            [miltonStorageDai.address, miltonStorageUsdt.address, miltonStorageUsdc.address],
            [josephDai.address, josephUsdt.address, josephUsdc.address]
        );

        //when
        await openSwapPayFixed(testData, paramsDai);
        await openSwapPayFixed(testData, paramsUsdc);
        await openSwapPayFixed(testData, paramsUsdt);

        const responseDai = await miltonFacadeDataProvider
            .connect(paramsDai.from)
            .getMySwaps(paramsDai.asset, ZERO, BigNumber.from(50));
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
        // await testCasePagination(0, 0, 0, 0, "IPOR_009");
        await testCasePagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            ZERO,
            ZERO,
            "IPOR_009",
            miltonSpreadModel
        );
    });

    it("should fail when page size is greater than 50", async () => {
        await testCasePagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            BigNumber.from("51"),
            ZERO,
            "IPOR_010",
            miltonSpreadModel
        );
    });

    it("should receive empty list of swaps", async () => {
        await testCasePagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCasePagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("should receive limited swap array", async () => {
        await testCasePagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("11"),
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("should receive limited swap array with offset", async () => {
        // await testCasePagination(22, 10, 10, 10, null);
        await testCasePagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("10"),
            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("should receive rest of swaps only", async () => {
        await testCasePagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            BigNumber.from("2"),
            null,
            miltonSpreadModel
        );
    });

    it("should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCasePagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("20"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });
});
