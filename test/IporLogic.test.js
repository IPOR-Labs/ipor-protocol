const { expect } = require("chai");
const { ethers } = require("hardhat");

const { assertError, prepareData, prepareTestData } = require("./Utils");

const { TC_TOTAL_AMOUNT_10_000_18DEC, ZERO } = require("./Const.js");
const ONE_18DEC = BigInt("1000000000000000000");
const YEAR_IN_SECONDS = BigInt("31536000");

describe("IporLogic", () => {
    let admin;
    let iporLogic;

    before(async () => {
        [admin] = await ethers.getSigners();
        const MockIporLogic = await ethers.getContractFactory("MockIporLogic");
        iporLogic = await MockIporLogic.deploy();
        await iporLogic.deployed();
    });

    it("Should accrue Ibt Price Decimals 18", async () => {
        //given
        const initialTimestamp = BigInt(Math.floor(Date.now() / 1000));
        const initialQuasiIbtPrice = ONE_18DEC * YEAR_IN_SECONDS;

        const ipor = {
            asset: admin.address,
            indexValue: BigInt("30000000000000000"),
            quasiIbtPrice: initialQuasiIbtPrice,
            exponentialMovingAverage: BigInt("30000000000000000"),
            exponentialWeightedMovingVariance: BigInt("30000000000000000"),
            blockTimestamp: initialTimestamp,
        };

        const days25 = BigInt(60 * 60 * 24 * 25);
        const expectedIbtPrice = BigInt("1002054794520547945");
        //when
        const actualQuasiIbtPrice = await iporLogic.accrueQuasiIbtPrice(
            ipor,
            initialTimestamp + days25
        );
        //then
        expect(actualQuasiIbtPrice, "Incorrect IBT Price").to.be.equal(
            "31600800000000000000000000"
        );
    });

    it("Should accrue IbtPrice Two Calculations Decimals18", async () => {
        //given
        const initialTimestamp = BigInt(Math.floor(Date.now() / 1000));
        const initialQuasiIbtPrice = ONE_18DEC * YEAR_IN_SECONDS;

        const ipor = {
            asset: admin.address,
            indexValue: BigInt("30000000000000000"),
            quasiIbtPrice: initialQuasiIbtPrice,
            exponentialMovingAverage: BigInt("30000000000000000"),
            exponentialWeightedMovingVariance: BigInt("30000000000000000"),
            blockTimestamp: initialTimestamp,
        };

        const days25 = BigInt(60 * 60 * 24 * 25);

        const firstCalculationTimestamp = initialTimestamp + days25;
        await iporLogic.accrueQuasiIbtPrice(ipor, firstCalculationTimestamp);

        const secondCalculationTimestamp = firstCalculationTimestamp + days25;

        //when
        const secondQuasiIbtPrice = await iporLogic.accrueQuasiIbtPrice(
            ipor,
            secondCalculationTimestamp
        );

        //then
        expect(secondQuasiIbtPrice, "Incorrect IBT Price").to.be.equal(
            "31665600000000000000000000"
        );
    });

    it("Should calculate Exponential Moving Average Two Calculations Decimals 18", async () => {
        //given
        const exponentialMovingAverage = BigInt("30000000000000000");
        const indexValue = BigInt("50000000000000000");
        const alfa = BigInt("10000000000000000");
        const expectedExponentialMovingAverage = "30200000000000000";

        //when
        const actualExponentialMovingAverage = await iporLogic.calculateExponentialMovingAverage(
            exponentialMovingAverage,
            indexValue,
            alfa
        );

        //then
        expect(actualExponentialMovingAverage, "Incorrect Exponential Moving Average").to.be.equal(
            expectedExponentialMovingAverage
        );
    });

    it("Should calculate Exponential Weighted Moving Variance - simple case 1 - Decimals 18", async () => {
        //given
        const lastExponentialWeightedMovingVariance = BigInt("0");
        const exponentialMovingAverage = BigInt("113000000000000000");
        const indexValue = BigInt("500000000000000000");
        const alfa = BigInt("100000000000000000");

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigInt("13479210000000000");

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - two calculations - Decimals 18", async () => {
        //given
        const alfa = BigInt("100000000000000000");

        const firstLastExponentialWeightedMovingVariance = BigInt("13479210000000000");
        const firstExponentialMovingAverage = BigInt("5000000000000000");
        const firstIndexValue = BigInt("50000000000000000");

        //first calculation
        const actualFirstExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                firstLastExponentialWeightedMovingVariance,
                firstExponentialMovingAverage,
                firstIndexValue,
                alfa
            );

        const secondLastExponentialWeightedMovingVariance = BigInt(
            actualFirstExponentialWeightedMovingVariance
        );

        const secondExponentialMovingAverage = BigInt("10500000000000000");
        const secondIndexValue = BigInt("60000000000000000");

        //when
        //second calculation
        const actualSecondExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                secondLastExponentialWeightedMovingVariance,
                secondExponentialMovingAverage,
                secondIndexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigInt("373539600000000");

        expect(
            actualSecondExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - two calculations - Decimals 18", async () => {
        //given
        const alfa = BigInt("100000000000000000");

        const firstLastExponentialWeightedMovingVariance = BigInt("13479210000000000");
        const firstExponentialMovingAverage = BigInt("5000000000000000");
        const firstIndexValue = BigInt("50000000000000000");

        //first calculation
        const actualFirstExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                firstLastExponentialWeightedMovingVariance,
                firstExponentialMovingAverage,
                firstIndexValue,
                alfa
            );

        const secondLastExponentialWeightedMovingVariance = BigInt(
            actualFirstExponentialWeightedMovingVariance
        );

        const secondExponentialMovingAverage = BigInt("10500000000000000");
        const secondIndexValue = BigInt("60000000000000000");

        //when
        //second calculation
        const actualSecondExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                secondLastExponentialWeightedMovingVariance,
                secondExponentialMovingAverage,
                secondIndexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigInt("373539600000000");

        expect(
            actualSecondExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - IPOR Index < EMA (Exponential Moving Average) - Decimals 18", async () => {
        //given
        const alfa = BigInt("100000000000000000");

        const lastExponentialWeightedMovingVariance = BigInt("13479210000000000");
        const exponentialMovingAverage = BigInt("5000000000000000");
        const indexValue = BigInt("4000000000000000");

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigInt("1348011000000000");

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - IPOR Index = EMA (Exponential Moving Average) - Decimals 18", async () => {
        //given
        const alfa = BigInt("100000000000000000");

        const lastExponentialWeightedMovingVariance = BigInt("13479210000000000");
        const exponentialMovingAverage = BigInt("5000000000000000");
        const indexValue = BigInt("5000000000000000");

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigInt("1347921000000000");

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - IPOR Index > EMA (Exponential Moving Average), Alfa = 0 - Decimals 18", async () => {
        //given
        const alfa = ZERO;

        const lastExponentialWeightedMovingVariance = BigInt("13479210000000000");
        const exponentialMovingAverage = BigInt("5000000000000000");
        const indexValue = BigInt("6000000000000000");

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = ZERO;

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - IPOR Index > EMA (Exponential Moving Average), Alfa = 1 - Decimals 18", async () => {
        //given
        const alfa = BigInt("1000000000000000000");

        const lastExponentialWeightedMovingVariance = BigInt("13479210000000000");
        const exponentialMovingAverage = BigInt("5000000000000000");
        const indexValue = BigInt("6000000000000000");

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigInt("13479210000000000");

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should NOT calculate Exponential Weighted Moving Variance - EMVar (Exponential Weighted Moving Variance) > 1 - Decimals 18", async () => {
        //given
        const alfa = BigInt("250000000000000000");

        const lastExponentialWeightedMovingVariance = BigInt("1000000000000000000");
        const exponentialMovingAverage = BigInt("1000000000000000000");
        const indexValue = BigInt("4000000000000000000");

        //when
        await assertError(
            //when
            iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            ),
            //then
            "IPOR_323"
        );
    });

    it("Should NOT calculate Exponential Weighted Moving Variance - Alfa > 1 - Decimals 18", async () => {
        //given
        const alfa = BigInt("1000000000000000001");

        const lastExponentialWeightedMovingVariance = BigInt("0");
        const exponentialMovingAverage = BigInt("113000000000000000");
        const indexValue = BigInt("500000000000000000");

        //when
        await assertError(
            //when
            iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            ),
            //then
            "IPOR_324"
        );
    });
});
