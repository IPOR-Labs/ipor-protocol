const { expect } = require("chai");
const { ethers } = require("hardhat");
const keccak256 = require("keccak256");

const { USD_1_18DEC } = require("./Const.js");

const {
    getLibraries,
    prepareData,
    prepareMiltonSpreadCase2,
} = require("./Utils");

describe("MiltonSpreadModel - Spread Premium At Par Component", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let libraries;

    before(async () => {
        libraries = await getLibraries();
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(
            libraries,
            [admin, userOne, userTwo, userThree, liquidityProvider],
            1
        );
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("46265766473020359");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator != 0, KHist denominator == 0", async () => {
        //given
        const maxSpreadValue = BigInt("300000000000000000");

        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("50000000000000000");
        const exponentialMovingAverage = BigInt("1050000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = maxSpreadValue;

        //then
        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator == 0, KHist denominator != 0", async () => {
        //given
        const maxSpreadValue = BigInt("300000000000000000");

        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = maxSpreadValue;

        //then
        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi > Ii, KVol denominator == 0, KHist denominator == 0", async () => {
        //given
        const maxSpreadValue = BigInt("300000000000000000");

        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("50000000000000000");
        const exponentialMovingAverage = BigInt("1050000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = maxSpreadValue;

        //then
        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi < Ii, KVol denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("32124352331606218");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi < Ii, KVol denominator == 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi == Ii, KVol denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("46124352331606218");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Pay Fixed, EMAi == Ii, KVol denominator == 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = iporIndexValue;
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("46410066617320504");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator != 0, KHist denominator == 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const iporIndexValue = BigInt("1050000000000000000");
        const exponentialMovingAverage = BigInt("50000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator == 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const iporIndexValue = BigInt("60000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi < Ii, KVol denominator == 0, KHist denominator == 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");
        const iporIndexValue = BigInt("1050000000000000000");
        const exponentialMovingAverage = BigInt("50000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi > Ii, KVol denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("33000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("32124352331606218");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi > Ii, KVol denominator == 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");
        const iporIndexValue = BigInt("33000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi == Ii, KVol denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();

        const iporIndexValue = BigInt("33000000000000000");
        const exponentialMovingAverage = iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = BigInt("46124352331606218");
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });

    it("should calculate spread - at par component - Rec Fixed, EMAi == Ii, KVol denominator == 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase2();
        const spreadPremiumsMaxValue = BigInt("300000000000000000");

        const iporIndexValue = BigInt("33000000000000000");
        const exponentialMovingAverage = iporIndexValue;
        const exponentialWeightedMovingVariance = USD_1_18DEC;

        //when
        let actualSpreadAtParComponentValue = BigInt(
            await miltonSpread
                .connect(userOne)
                .calculateAtParComponentRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance
                )
        );

        const expectedSpreadAtParComponentValue = spreadPremiumsMaxValue;
        //then

        expect(
            actualSpreadAtParComponentValue,
            `Incorrect spread at par component value actual: ${actualSpreadAtParComponentValue}, expected: ${expectedSpreadAtParComponentValue}`
        ).to.be.eq(expectedSpreadAtParComponentValue);
    });
});
