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
    grantAllSpreadRoles,
} = require("./Utils");

describe("MiltonSpreadModel - Pay Fixed", () => {
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
        await grantAllSpreadRoles(data, admin, userOne);
    });

    it("should calculate Spread Pay Fixed Value - Kf part + KOmega part + KVol part + KHist < Spread Max Value", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = BigInt("107709997242251128");

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = payFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = payFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("307589880159786950")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = payFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = payFixedDerivativesBalance;

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("1000000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage =
            BigInt("1000000000000000000") + iporIndexValue;
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf part very high, Komega part normal, KVol part normal, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("0"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("100000000000000001500");
        const derivativeDeposit = BigInt("1000");
        const derivativeOpeningFee = BigInt("0");

        const payFixedDerivativesBalance = BigInt("1000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("100");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                // .callStatic
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf part normal, KOmega part very high, KVol part normal, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("999999999999999999000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part very high, KHist part normal", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("999999999999999899");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part normal, KHist very high", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("2000000000000000010");
        const exponentialMovingAverage = BigInt("3000000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should calculate Spread Pay Fixed Value = Spread Max Value - Kf part + KOmega part + KVol part + KHist > Spread Max Value", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("300000009000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("15000000000000000000000");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("20000000000000000000");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        const expectedSpreadValue = spreadMaxValue;

        //when
        let actualSpreadValue = BigInt(
            await data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it("should NOT calculate Spread Pay Fixed - Liquidity Pool + Opening Fee = 0", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );

        const spreadMaxValue = BigInt("300000000000000000");

        await data.miltonSpread
            .connect(userOne)
            .setSpreadMaxValue(spreadMaxValue);

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(
                BigInt("1000000000000000000")
            );

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentLambdaValue(BigInt("300000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKfValue(BigInt("1000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKVolValue(BigInt("31000000000000000"));

        await data.miltonSpread
            .connect(userOne)
            .setAtParComponentKHistValue(BigInt("14000000000000000"));

        const liquidityPool = BigInt("0");
        const derivativeDeposit = BigInt("10000000000000000000000");
        const derivativeOpeningFee = BigInt("0");

        const payFixedDerivativesBalance = BigInt("1000000000000000000000");
        const recFixedDerivativesBalance = BigInt("13000000000000000000000");

        const soap = BigInt("500000000000000000000");

        const iporIndexValue = BigInt("30000000000000000");
        const exponentialMovingAverage = BigInt("40000000000000000");
        const exponentialWeightedMovingVariance = BigInt("35000000000000000");

        await assertError(
            //when
            data.miltonSpread
                .connect(userOne)
                .testCalculateSpreadPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage,
                    exponentialWeightedMovingVariance,
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    soap
                ),
            //then
            "IPOR_49"
        );
    });
});
