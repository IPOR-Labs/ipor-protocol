const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");
const { utils } = require("web3");

const {
    USD_1_18DEC,
    USD_20_18DEC,
    USD_2_000_18DEC,
    PERCENTAGE_3_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_13_000_18DEC,
    USD_14_000_18DEC,
    USD_15_000_18DEC,
    USD_28_000_18DEC,
    USD_100_18DEC,
    USD_500_18DEC,
    ZERO,
    USD_10_000_000_18DEC,
} = require("./Const.js");

const {
    assertError,
    prepareData,
    prepareTestData,
    prepareMiltonSpreadBase,
    prepareMiltonSpreadCase6,
    prepareMiltonSpreadCase7,
    prepareMiltonSpreadCase8,
    prepareMiltonSpreadCase9,
    prepareMiltonSpreadCase10,
    prepareMiltonSpreadCase11,
    setupTokenUsdtInitialValuesForUsers,
    getPayFixedDerivativeParamsDAICase1,
    setupTokenDaiInitialValuesForUsers,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareApproveForUsers,
} = require("./Utils");

describe("MiltonSpreadModel - Rec Fixed", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            0
        );
    });

    it("should calculate Quote Value Receive Fixed Value - Spread Premium < Spread Premium Max Value, refLeg < spreadPremiums", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const soap = BigInt("500000000000000000000");
        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;
        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: ZERO,
            exponentialMovingAverage: BigInt("400000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };
        const accruedBalance = {
            payFixedSwaps: BigInt("1000000000000000000000") + swapCollateral,
            receiveFixedSwaps: USD_13_000_18DEC,
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: liquidityPoolBalance + openingFee,
            treasury: ZERO,
        };

        const expectedQuoteValue = BigInt("0");

        //when
        let actualQuotedValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .callStatic.calculateQuoteReceiveFixed(
                    soap,
                    accruedIpor,
                    accruedBalance
                )
        );

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });

    it("should calculate Quote Value Receive Fixed Value - Spread Premium < Spread Premium Max Value, refLeg > spreadPremiums", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const soap = USD_500_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;
        const accruedIpor = {
            indexValue: BigInt("150000000000000000"),
            ibtPrice: ZERO,
            exponentialMovingAverage: BigInt("400000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const accruedBalance = {
            payFixedSwaps: BigInt("1000000000000000000000") + swapCollateral,
            receiveFixedSwaps: USD_13_000_18DEC,
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: USD_15_000_18DEC + openingFee,
            treasury: ZERO,
        };

        const expectedQuoteValue = BigInt("79240004104037346");

        //when
        let actualQuotedValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateQuoteReceiveFixed(soap, accruedIpor, accruedBalance)
        );

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });

    it("should calculate Spread Premiums Rec Fixed - Kf part + Komega part + KVol part + KHist < Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = BigInt("67234296309197255");

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };
        const expectedSpreadValue = spreadPremiumsMaxValue;

        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .calculateAdjustedUtilizationRateRecFixed(
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral,
                    BigInt("300000000000000000")
                )
        );

        const expectedAdjustedUtilizationRate = BigInt("692410119840213050");

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(
            actualAdjustedUtilizationRate
        );
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = receiveFixedSwapsBalance;

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = receiveFixedSwapsBalance;

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = receiveFixedSwapsBalance;

        const iporIndexValue = BigInt("30000000000000000");

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage:
                BigInt("1000000000000000000") + iporIndexValue,
            exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = receiveFixedSwapsBalance;

        const iporIndexValue = BigInt("30000000000000000");

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage:
                BigInt("1000000000000000000") + iporIndexValue,
            exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage:
                BigInt("1000000000000000000") + iporIndexValue,
            exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage:
                BigInt("1000000000000000000") + iporIndexValue,
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part very high, KOmega part normal, KVol part normal, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase9();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");
        const liquidityPoolBalance = BigInt("100000000000000000000");
        const swapCollateral = BigInt("1000000000000000");
        const swapOpeningFee = BigInt("0");

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("99990000000000000000");

        const soap = BigInt("100");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part very high, KVol part normal, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigInt("300000000000000000");
        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = USD_100_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("999999999999999999000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part very high, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("999999999999999899"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part normal, KHist very high", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigInt("300000000000000000");
        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("3000000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("2000000000000000010"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate spread Premiums Rec Fixed = Spread Max Value - Kf part + Komega part + KVol part + KHist > Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase11();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = USD_20_18DEC;

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
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

        const liquidityPoolBalance = BigInt("0");
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const swapOpeningFee = BigInt("0");

        const payFixedSwapsBalance = USD_13_000_18DEC;
        const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const accruedIpor = {
            indexValue: BigInt("30000000000000000"),
            ibtPrice: BigInt("1000000000000000000"),
            exponentialMovingAverage: BigInt("40000000000000000"),
            exponentialWeightedMovingVariance: BigInt("35000000000000000"),
        };
        //when
        await assertError(
            //when
            miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsRecFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance + swapOpeningFee,
                    payFixedSwapsBalance,
                    receiveFixedSwapsBalance + swapCollateral
                ),
            //then
            "IPOR_49"
        );
    });

    it("should calculate Spread Receive Fixed - simple case 1 - initial state with Liquidity Pool", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1
        );
        const calculateTimestamp = Math.floor(Date.now() / 1000);
        const expectedSpreadReceiveFixed = BigInt("360000000000000");
        const timestamp = Math.floor(Date.now() / 1000);

        await prepareApproveForUsers(
            [liquidityProvider],
            "DAI",
            data,
            testData
        );

        await setupTokenDaiInitialValuesForUsers([liquidityProvider], testData);
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_18DEC, timestamp);

        //when
        let actualSpreadValue = await testData.miltonDai
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(BigInt(await actualSpreadValue.spreadRecFixedValue)).to.be.eq(
            expectedSpreadReceiveFixed
        );
    });

    it("should calculate Spread Receive Fixed - spread premiums higher than IPOR Index", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            1
        );

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let balanceLiquidityPool = BigInt("10000000000");

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

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(balanceLiquidityPool, params.openTimestamp);

        await testData.miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("1000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        const calculateTimestamp = Math.floor(Date.now() / 1000);
        const expectedSpreadReceiveFixed = BigInt("0");

        //when
        let actualSpreadValue = await testData.miltonUsdt
            .connect(userOne)
            .callStatic.itfCalculateSpread(params.openTimestamp + 1);

        //then
        expect(parseInt(await actualSpreadValue.spreadRecFixedValue)).to.be.gt(
            0
        );
    });

    it("should calculate Spread Receive Fixed - simple case 1 - initial state with Liquidity Pool", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            0
        );
        const calculateTimestamp = Math.floor(Date.now() / 1000);
        const expectedSpreadReceiveFixed = BigInt("360000000000000");
        const timestamp = Math.floor(Date.now() / 1000);

        await prepareApproveForUsers(
            [liquidityProvider],
            "DAI",
            data,
            testData
        );

        await setupTokenDaiInitialValuesForUsers([liquidityProvider], testData);
        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_18DEC, timestamp);

        //when
        let actualSpreadValue = await testData.miltonDai
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(BigInt(await actualSpreadValue.spreadRecFixedValue)).to.be.eq(
            expectedSpreadReceiveFixed
        );
    });

    it("should calculate Spread Receive Fixed - spread premiums higher than IPOR Index", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            data,
            0,
            0
        );

        const params = getPayFixedDerivativeParamsUSDTCase1(userTwo, testData);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                params.asset,
                PERCENTAGE_3_18DEC,
                params.openTimestamp
            );

        let balanceLiquidityPool = BigInt("10000000000");

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

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(balanceLiquidityPool, params.openTimestamp);

        await testData.miltonUsdt
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigInt("1000000000"),
                params.slippageValue,
                params.collateralizationFactor
            );

        const calculateTimestamp = Math.floor(Date.now() / 1000);
        const expectedSpreadReceiveFixed = BigInt("0");

        //when
        let actualSpreadValue = await testData.miltonUsdt
            .connect(userOne)
            .callStatic.itfCalculateSpread(params.openTimestamp + 1);

        //then
        expect(parseInt(await actualSpreadValue.spreadRecFixedValue)).to.be.gt(
            0
        );
    });
});
