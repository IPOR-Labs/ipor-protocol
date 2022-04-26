import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N1__0_18DEC,
    N0__001_18DEC,
    PERCENTAGE_3_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_100_18DEC,
    USD_500_18DEC,
    USD_15_000_18DEC,
    USD_13_000_18DEC,
    USD_20_18DEC,
    USD_10_000_000_6DEC,
    USD_10_000_000_18DEC,
    ZERO,
    N0__01_18DEC,
} from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockMiltonSpreadModel,
    prepareMiltonSpreadBase,
    prepareMiltonSpreadCase6,
    prepareMiltonSpreadCase8,
    prepareMiltonSpreadCase9,
    prepareMiltonSpreadCase10,
    prepareMiltonSpreadCase11,
    getPayFixedDerivativeParamsUSDTCase1,
} from "../utils/MiltonUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
    setupTokenUsdcInitialValuesForUsers,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("MiltonSpreadRecFixed", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.BASE);
    });

    it("should calculate Quote Value Receive Fixed Value - Spread Premium < Spread Premium Max Value, Base Case 1, Spread negative", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const soap = BigNumber.from("500").mul(N1__0_18DEC);
        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;

        const accruedIpor = {
            indexValue: BigNumber.from("13").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };
        const accruedBalance = {
            totalCollateralPayFixed: BigNumber.from("1000").mul(N1__0_18DEC).add(swapCollateral),
            totalCollateralReceiveFixed: USD_13_000_18DEC,
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: liquidityPoolBalance.add(openingFee),
            treasury: ZERO,
        };

        const expectedQuoteValue = BigNumber.from("217899151046690308");

        //when
        let actualQuotedValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .callStatic.calculateQuoteReceiveFixed(soap, accruedIpor, accruedBalance)
        );

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });

    it.skip("should calculate Quote Value Receive Fixed Value - Spread Premium < Spread Premium Max Value, refLeg < spreadPremiums", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const soap = BigNumber.from("500").mul(N1__0_18DEC);
        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;
        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: ZERO,
            exponentialMovingAverage: BigNumber.from("40").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };
        const accruedBalance = {
            totalCollateralPayFixed: BigNumber.from("1000").mul(N1__0_18DEC).add(swapCollateral),
            totalCollateralReceiveFixed: USD_13_000_18DEC,
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: liquidityPoolBalance.add(openingFee),
            treasury: ZERO,
        };

        const expectedQuoteValue = ZERO;

        //when
        let actualQuotedValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .callStatic.calculateQuoteReceiveFixed(soap, accruedIpor, accruedBalance)
        );

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });

    it.skip("should calculate Quote Value Receive Fixed Value - Spread Premium < Spread Premium Max Value, refLeg > spreadPremiums", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const soap = USD_500_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;
        const accruedIpor = {
            indexValue: BigNumber.from("15").mul(N0__01_18DEC),
            ibtPrice: ZERO,
            exponentialMovingAverage: BigNumber.from("40").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const accruedBalance = {
            totalCollateralPayFixed: BigNumber.from("1000").mul(N1__0_18DEC).add(swapCollateral),
            totalCollateralReceiveFixed: USD_13_000_18DEC,
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: USD_15_000_18DEC.add(openingFee),
            treasury: ZERO,
        };

        const expectedQuoteValue = BigNumber.from("79240004104037346");

        //when
        let actualQuotedValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .calculateQuoteReceiveFixed(soap, accruedIpor, accruedBalance)
        );

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed - Kf part + Komega part + KVol part + KHist < Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = BigNumber.from("67234296309197255");

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };
        const expectedSpreadValue = spreadPremiumsMaxValue;

        let actualAdjustedUtilizationRate = BigNumber.from(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRateRecFixed(
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral),
                    BigNumber.from("30").mul(N0__01_18DEC)
                )
        );

        const expectedAdjustedUtilizationRate = BigNumber.from("692410119840213050");

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(actualAdjustedUtilizationRate);
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = totalCollateralReceiveFixedBalance;

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = totalCollateralReceiveFixedBalance;

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("1").mul(N1__0_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = totalCollateralReceiveFixedBalance;

        const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("1").mul(N1__0_18DEC).add(iporIndexValue),
            exponentialWeightedMovingVariance: BigNumber.from("1").mul(N1__0_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = totalCollateralReceiveFixedBalance;

        const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("1").mul(N1__0_18DEC).add(iporIndexValue),
            exponentialWeightedMovingVariance: BigNumber.from("1").mul(N1__0_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();
        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("1").mul(N1__0_18DEC).add(iporIndexValue),
            exponentialWeightedMovingVariance: BigNumber.from("1").mul(N1__0_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();
        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("1").mul(N1__0_18DEC).add(iporIndexValue),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part very high, KOmega part normal, KVol part normal, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase9();
        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);
        const liquidityPoolBalance = BigNumber.from("100").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("1000000000000000");
        const swapOpeningFee = ZERO;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("99990000000000000000");

        const soap = BigNumber.from("100");

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part very high, KVol part normal, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);
        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = USD_100_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("999999999999999999000");

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part very high, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("999999999999999899"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part normal, KHist very high", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);
        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N1__0_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("2000000000000000010"),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate spread Premiums Rec Fixed = Spread Max Value - Kf part + Komega part + KVol part + KHist > Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase11();
        const spreadPremiumsMaxValue = BigNumber.from("30").mul(N0__01_18DEC);

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should NOT calculate Spread Premiums Rec Fixed - Liquidity Pool + Opening Fee = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const liquidityPoolBalance = ZERO;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = ZERO;

        const totalCollateralPayFixedBalance = USD_13_000_18DEC;
        const totalCollateralReceiveFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: BigNumber.from("1").mul(N1__0_18DEC),
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };
        //when
        await assertError(
            //when
            miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance,
                    totalCollateralReceiveFixedBalance.add(swapCollateral)
                ),
            //then
            "IPOR_321"
        );
    });
    it("should calculate Spread Receive Fixed, DAI - simple case 1 - initial state with Liquidity Pool", async () => {
        //given
        const calculateTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const testData = await prepareTestData(
            calculateTimestamp,
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [BigNumber.from("0")],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const { josephDai, miltonDai } = testData;
        if (josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedSpreadReceiveFixed = BigNumber.from("-433406136001736");

        await prepareApproveForUsers([liquidityProvider], "DAI", testData);

        await setupTokenDaiInitialValuesForUsers([liquidityProvider], testData);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_18DEC, calculateTimestamp);

        //when
        let actualSpreadValue = await miltonDai
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(actualSpreadValue.spreadReceiveFixed).to.be.eq(expectedSpreadReceiveFixed);
    });

    it("should calculate Spread Receive Fixed, DAI - simple case 2 - initial state with Liquidity Pool", async () => {
        //given
        const calculateTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const testData = await prepareTestData(
            calculateTimestamp,
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const { josephDai, miltonDai } = testData;
        if (josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedSpreadReceiveFixed = BigNumber.from("-7056293847751");

        await prepareApproveForUsers([liquidityProvider], "DAI", testData);

        await setupTokenDaiInitialValuesForUsers([liquidityProvider], testData);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_18DEC, calculateTimestamp);

        //when
        let actualSpreadValue = await miltonDai
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(actualSpreadValue.spreadReceiveFixed).to.be.eq(expectedSpreadReceiveFixed);
    });

    it("should calculate Spread Receive Fixed, USDC - simple case 1 - initial state with Liquidity Pool", async () => {
        //given
        const calculateTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const testData = await prepareTestData(
            calculateTimestamp,
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDC"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const { josephUsdc, miltonUsdc, tokenUsdc } = testData;
        if (josephUsdc === undefined || miltonUsdc === undefined || tokenUsdc === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedSpreadReceiveFixed = BigNumber.from("-7056293847751");

        await prepareApproveForUsers([liquidityProvider], "USDC", testData);

        await setupTokenUsdcInitialValuesForUsers([liquidityProvider], tokenUsdc);

        await josephUsdc
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_6DEC, calculateTimestamp);

        //when
        let actualSpreadValue = await miltonUsdc
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(actualSpreadValue.spreadReceiveFixed).to.be.eq(expectedSpreadReceiveFixed);
    });

    it("should calculate Spread Receive Fixed - spread premiums higher than IPOR Index", async () => {
        //given
        let testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { iporOracle, josephUsdt, miltonUsdt, tokenUsdt } = testData;
        if (josephUsdt === undefined || miltonUsdt === undefined || tokenUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        let balanceLiquidityPool = BigNumber.from("10000000000");

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(balanceLiquidityPool, params.openTimestamp);

        await miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("1000000000"),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //when
        const actualSpreadValue = await miltonUsdt
            .connect(userOne)
            .itfCalculateSpread(params.openTimestamp.add(BigNumber.from("1")));

        //then
        expect(actualSpreadValue.spreadReceiveFixed.eq(BigNumber.from("-433406136001736"))).to.be
            .true;
    });
});
