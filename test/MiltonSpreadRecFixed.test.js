const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");
const { utils } = require("web3");

const {
    USD_1_18DEC,
    USD_20_18DEC,
    USD_2_000_18DEC,
    USD_10_000_18DEC,
    USD_14_000_18DEC,
    ZERO,
} = require("./Const.js");

const {
    assertError,
    getLibraries,
    prepareData,
    prepareTestData,
    prepareMiltonSpreadBase,
    prepareMiltonSpreadCase6,
    prepareMiltonSpreadCase8,
    prepareMiltonSpreadCase9,
    prepareMiltonSpreadCase10,
    prepareMiltonSpreadCase11,
} = require("./Utils");

describe("MiltonSpreadModel - Rec Fixed", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let libraries;

    before(async () => {
        libraries = await getLibraries();
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(libraries, [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
        ]);
    });

    // it("should calculate Quote Value Receive Fixed Value - Spread Premium < Spread Premium Max Value, Ref Leg Case 1", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadBase();

    //     const soap = BigInt("500000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const openingFee = BigInt("20000000000000000000");
    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: ZERO,
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };
    //     const accruedBalance = {
    //         payFixedSwaps: BigInt("1000000000000000000000") + swapCollateral,
    //         receiveFixedSwaps: BigInt("13000000000000000000000"),
    //         openingFee: openingFee,
    //         liquidationDeposit: ZERO,
    //         iporPublicationFee: ZERO,
    //         liquidityPool: BigInt("15000000000000000000000") + openingFee,
    //         treasury: ZERO,
    //     };

    //     const expectedQuoteValue = BigInt("26608345954563572");

    //     //when
    //     let actualQuotedValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .calculateQuoteReceiveFixed(
    //                 soap,
    //                 accruedIpor,
    //                 accruedBalance,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    // });

    // it("should calculate Quote Value Receive Fixed Value - Spread Premium < Spread Premium Max Value, Ref Leg Case 2", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadBase();

    //     const soap = BigInt("500000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const openingFee = BigInt("20000000000000000000");
    //     const accruedIpor = {
    //         indexValue: BigInt("55000000000000000"),
    //         ibtPrice: ZERO,
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };
    //     const accruedBalance = {
    //         payFixedSwaps: BigInt("1000000000000000000000") + swapCollateral,
    //         receiveFixedSwaps: BigInt("13000000000000000000000"),
    //         openingFee: openingFee,
    //         liquidationDeposit: ZERO,
    //         iporPublicationFee: ZERO,
    //         liquidityPool: BigInt("15000000000000000000000") + openingFee,
    //         treasury: ZERO,
    //     };

    //     const expectedQuoteValue = BigInt("35593117528167633");

    //     //when
    //     let actualQuotedValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .calculateQuoteReceiveFixed(
    //                 soap,
    //                 accruedIpor,
    //                 accruedBalance,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed - Kf part + Komega part + KVol part + KHist < Spread Max Value", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase10();

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };

    //     const expectedSpreadValue = BigInt("93497295658845706");

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //given

    //     const miltonSpread = await prepareMiltonSpreadCase8();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase8();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };
    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase8();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = receiveFixedSwapsBalance;

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase8();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = receiveFixedSwapsBalance;

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase8();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = receiveFixedSwapsBalance;

    //     const iporIndexValue = BigInt("30000000000000000");

    //     const accruedIpor = {
    //         indexValue: iporIndexValue,
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage:
    //             BigInt("1000000000000000000") + iporIndexValue,
    //         exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase6();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = receiveFixedSwapsBalance;

    //     const iporIndexValue = BigInt("30000000000000000");

    //     const accruedIpor = {
    //         indexValue: iporIndexValue,
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage:
    //             BigInt("1000000000000000000") + iporIndexValue,
    //         exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase6();
    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const iporIndexValue = BigInt("30000000000000000");

    //     const accruedIpor = {
    //         indexValue: iporIndexValue,
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage:
    //             BigInt("1000000000000000000") + iporIndexValue,
    //         exponentialWeightedMovingVariance: BigInt("1000000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase8();
    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const iporIndexValue = BigInt("30000000000000000");

    //     const accruedIpor = {
    //         indexValue: iporIndexValue,
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage:
    //             BigInt("1000000000000000000") + iporIndexValue,
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part very high, KOmega part normal, KVol part normal, KHist part normal", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase9();
    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");
    //     const liquidityPoolBalance = BigInt("100000000000000001500");
    //     const swapCollateral = BigInt("10000");
    //     const swapOpeningFee = BigInt("0");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000");

    //     const soap = BigInt("100");

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part very high, KVol part normal, KHist part normal", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase6();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");
    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("999999999999999999000");

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part very high, KHist part normal", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase6();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("999999999999999899"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate Spread Premiums Rec Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part normal, KHist very high", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase6();

    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");
    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const accruedIpor = {
    //         indexValue: BigInt("3000000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("2000000000000000010"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should calculate spread Premiums Rec Fixed = Spread Max Value - Kf part + Komega part + KVol part + KHist > Spread Max Value", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase11();
    //     const spreadPremiumsMaxValue = BigInt("300000000000000000");

    //     const liquidityPoolBalance = BigInt("15000000000000000000000");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("20000000000000000000");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };

    //     const expectedSpreadValue = spreadPremiumsMaxValue;

    //     //when
    //     let actualSpreadValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             )
    //     );

    //     //then
    //     expect(
    //         actualSpreadValue,
    //         `Incorrect Rec Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
    //     ).to.be.eq(expectedSpreadValue);
    // });

    // it("should NOT calculate Spread Premiums Rec Fixed - Liquidity Pool + Opening Fee = 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase6();

    //     const liquidityPoolBalance = BigInt("0");
    //     const swapCollateral = BigInt("10000000000000000000000");
    //     const swapOpeningFee = BigInt("0");

    //     const payFixedSwapsBalance = BigInt("13000000000000000000000");
    //     const receiveFixedSwapsBalance = BigInt("1000000000000000000000");

    //     const soap = BigInt("500000000000000000000");

    //     const accruedIpor = {
    //         indexValue: BigInt("30000000000000000"),
    //         ibtPrice: BigInt("1000000000000000000"),
    //         exponentialMovingAverage: BigInt("40000000000000000"),
    //         exponentialWeightedMovingVariance: BigInt("35000000000000000"),
    //     };
    //     //when
    //     await assertError(
    //         //when
    //         miltonSpread
    //             .connect(userOne)
    //             .testCalculateSpreadPremiumsRecFixed(
    //                 soap,
    //                 accruedIpor,
    //                 liquidityPoolBalance + swapOpeningFee,
    //                 payFixedSwapsBalance,
    //                 receiveFixedSwapsBalance + swapCollateral,
    //                 swapCollateral
    //             ),
    //         //then
    //         "IPOR_49"
    //     );
    // });

    it("should calculate Spread Receive Fixed - simple case 1 - initial state", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        const calculateTimestamp = Math.floor(Date.now() / 1000);
        const expectedSpreadReceiveFixed = BigInt("0");

        //when
        let actualSpreadValue = await testData.miltonDai
            .connect(userOne)
            .itfCalculateSpread(calculateTimestamp);

        console.log(actualSpreadValue);

        //then
        expect(BigInt(await actualSpreadValue.spreadRecFixedValue)).to.be.eq(
            expectedSpreadReceiveFixed
        );
    });

	it("should calculate Spread Receive Fixed - simple case 1 - ", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0
        );
        const calculateTimestamp = Math.floor(Date.now() / 1000);
        const expectedSpreadReceiveFixed = BigInt("0");

        //when
        let actualSpreadValue = await testData.miltonDai
            .connect(userOne)
            .itfCalculateSpread(calculateTimestamp);

        console.log(actualSpreadValue);

        //then
        expect(BigInt(await actualSpreadValue.spreadRecFixedValue)).to.be.eq(
            expectedSpreadReceiveFixed
        );
    });
});
