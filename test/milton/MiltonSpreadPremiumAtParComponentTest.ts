import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { N0__001_18DEC, N0__1_18DEC, USD_1_18DEC, N0__01_18DEC } from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    prepareMiltonSpreadCase2,
} from "../utils/MiltonUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Spread Premium At Par Component", () => {
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

    // it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("4").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = BigNumber.from("35").mul(N0__001_18DEC);

    //     //when
    //     let actualSpreadAtParComponentValue = BigInt(
    //         await miltonSpread
    //             .connect(userOne)
    //             .calculateAtParComponentPayFixed(
    //                 iporIndexValue,
    //                 exponentialMovingAverage,
    //                 exponentialWeightedMovingVariance
    //             )
    //     );

    //     const expectedSpreadAtParComponentValue = BigNumber.from("46265766473020359");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator != 0, KHist denominator == 0", async () => {
    //     //given
    //     const maxSpreadValue = BigNumber.from("3").mul(N0__1_18DEC);

    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("5").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("105").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = BigNumber.from("35").mul(N0__001_18DEC);

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentPayFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = maxSpreadValue;

    //     //then
    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator == 0, KHist denominator != 0", async () => {
    //     //given
    //     const maxSpreadValue = BigNumber.from("3").mul(N0__1_18DEC);

    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("4").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentPayFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = maxSpreadValue;

    //     //then
    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator == 0, KHist denominator == 0", async () => {
    //     //given
    //     const maxSpreadValue = BigNumber.from("3").mul(N0__1_18DEC);

    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("5").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("105").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentPayFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = maxSpreadValue;

    //     //then
    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi < Ii, KVol denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("6").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("4").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = BigNumber.from("35").mul(N0__001_18DEC);

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentPayFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = BigNumber.from("32124352331606218");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi < Ii, KVol denominator == 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();
    //     const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

    //     const iporIndexValue = BigNumber.from("6").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("4").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentPayFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi == Ii, KVol denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("6").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = iporIndexValue;
    //     const exponentialWeightedMovingVariance = BigNumber.from("35").mul(N0__001_18DEC);

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentPayFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = BigNumber.from("46124352331606218");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Pay Fixed, EMAi == Ii, KVol denominator == 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();
    //     const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

    //     const iporIndexValue = BigNumber.from("6").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = iporIndexValue;
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentPayFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator != 0, KHist denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("6").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("4").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = BigNumber.from("35").mul(N0__001_18DEC);

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentRecFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = BigNumber.from("46410066617320504");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator != 0, KHist denominator == 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();
    //     const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

    //     const iporIndexValue = BigNumber.from("105").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("5").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = BigNumber.from("35").mul(N0__001_18DEC);

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentRecFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator == 0, KHist denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();
    //     const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

    //     const iporIndexValue = BigNumber.from("6").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("4").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentRecFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator == 0, KHist denominator == 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();
    //     const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);
    //     const iporIndexValue = BigNumber.from("105").mul(N0__01_18DEC);
    //     const exponentialMovingAverage = BigNumber.from("5").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentRecFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );

    //     const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi > Ii, KVol denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("33000000000000000");
    //     const exponentialMovingAverage = BigNumber.from("4").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = BigNumber.from("35").mul(N0__001_18DEC);

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentRecFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );

    //     const expectedSpreadAtParComponentValue = BigNumber.from("32124352331606218");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi > Ii, KVol denominator == 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();
    //     const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);
    //     const iporIndexValue = BigNumber.from("33000000000000000");
    //     const exponentialMovingAverage = BigNumber.from("4").mul(N0__01_18DEC);
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentRecFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );
    //     const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi == Ii, KVol denominator != 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();

    //     const iporIndexValue = BigNumber.from("33000000000000000");
    //     const exponentialMovingAverage = iporIndexValue;
    //     const exponentialWeightedMovingVariance = BigNumber.from("35").mul(N0__001_18DEC);

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentRecFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );

    //     const expectedSpreadAtParComponentValue = BigNumber.from("46124352331606218");
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });

    // it("should calculate spread - at par component - Rec Fixed, EMAi == Ii, KVol denominator == 0", async () => {
    //     //given
    //     const miltonSpread = await prepareMiltonSpreadCase2();
    //     const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

    //     const iporIndexValue = BigNumber.from("33000000000000000");
    //     const exponentialMovingAverage = iporIndexValue;
    //     const exponentialWeightedMovingVariance = USD_1_18DEC;

    //     //when
    //     const actualSpreadAtParComponentValue = await miltonSpread
    //         .connect(userOne)
    //         .calculateAtParComponentRecFixed(
    //             iporIndexValue,
    //             exponentialMovingAverage,
    //             exponentialWeightedMovingVariance
    //         );

    //     const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
    //     //then

    //     expect(
    //         actualSpreadAtParComponentValue,
    //         `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
    //     ).to.be.eq(expectedSpreadAtParComponentValue);
    // });
});
