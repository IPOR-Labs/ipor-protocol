import hre from "hardhat";
import chai from "chai";
import { Signer } from "ethers";
import { BigNumber } from "ethers";
import { MockIporLogic } from "../types";
import { assertError } from "./utils/AssertUtils";
import { ZERO, ONE_18DEC, YEAR_IN_SECONDS } from "./utils/Constants";

const { expect } = chai;

describe("IporLogic", () => {
    const P_01_DEC18 = BigNumber.from("100000000000000000");
    const P_001_DEC18 = BigNumber.from("10000000000000000");
    const P_03_DEC18 = BigNumber.from("30000000000000000");
    const P_0004_DEC18 = BigNumber.from("4000000000000000");
    const P_05_DEC18 = BigNumber.from("500000000000000000");
    const P_005_DEC18 = BigNumber.from("50000000000000000");
    const P_0005_DEC18 = BigNumber.from("5000000000000000");
    const P_006_DEC18 = BigNumber.from("60000000000000000");
    const P_0006_DEC18 = BigNumber.from("6000000000000000");

    let admin: Signer;
    let iporLogic: MockIporLogic;

    before(async () => {
        [admin] = await hre.ethers.getSigners();
        const MockIporLogic = await hre.ethers.getContractFactory("MockIporLogic");
        iporLogic = (await MockIporLogic.deploy()) as MockIporLogic;
        await iporLogic.deployed();
    });

    it("Should accrue Ibt Price Decimals 18", async () => {
        //given
        const initialTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const initialQuasiIbtPrice = ONE_18DEC.mul(YEAR_IN_SECONDS);

        const ipor = {
            asset: await admin.getAddress(),
            indexValue: P_03_DEC18,
            quasiIbtPrice: initialQuasiIbtPrice,
            exponentialMovingAverage: P_03_DEC18,
            exponentialWeightedMovingVariance: P_03_DEC18,
            lastUpdateTimestamp: initialTimestamp,
        };

        const days25 = BigNumber.from(60 * 60 * 24 * 25);
        //when
        const actualQuasiIbtPrice = await iporLogic.accrueQuasiIbtPrice(
            ipor,
            initialTimestamp.add(days25)
        );
        //then
        expect(actualQuasiIbtPrice, "Incorrect IBT Price").to.be.equal(
            "31600800000000000000000000"
        );
    });

    it("Should accrue IbtPrice Two Calculations Decimals18", async () => {
        //given
        const initialTimestamp = BigNumber.from(Math.floor(Date.now() / 1000));
        const initialQuasiIbtPrice = ONE_18DEC.mul(YEAR_IN_SECONDS);

        const ipor = {
            asset: await admin.getAddress(),
            indexValue: P_03_DEC18,
            quasiIbtPrice: initialQuasiIbtPrice,
            exponentialMovingAverage: P_03_DEC18,
            exponentialWeightedMovingVariance: P_03_DEC18,
            lastUpdateTimestamp: initialTimestamp,
        };

        const days25 = BigNumber.from(60 * 60 * 24 * 25);

        const firstCalculationTimestamp = initialTimestamp.add(days25);
        await iporLogic.accrueQuasiIbtPrice(ipor, firstCalculationTimestamp);

        const secondCalculationTimestamp = firstCalculationTimestamp.add(days25);

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
        const exponentialMovingAverage = P_03_DEC18;
        const indexValue = P_005_DEC18;
        const alfa = P_001_DEC18;
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
        const lastExponentialWeightedMovingVariance = ZERO;
        const exponentialMovingAverage = BigNumber.from("113000000000000000");
        const indexValue = P_05_DEC18;
        const alfa = P_01_DEC18;

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigNumber.from("13479210000000000");

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - two calculations - Decimals 18", async () => {
        //given
        const alfa = P_01_DEC18;

        const firstLastExponentialWeightedMovingVariance = BigNumber.from("13479210000000000");
        const firstExponentialMovingAverage = P_0005_DEC18;
        const firstIndexValue = P_005_DEC18;

        //first calculation
        const actualFirstExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                firstLastExponentialWeightedMovingVariance,
                firstExponentialMovingAverage,
                firstIndexValue,
                alfa
            );

        const secondLastExponentialWeightedMovingVariance =
            actualFirstExponentialWeightedMovingVariance;

        const secondExponentialMovingAverage = BigNumber.from("10500000000000000");
        const secondIndexValue = P_006_DEC18;

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
        const expectedExponentialWeightedMovingVariance = BigNumber.from("373539600000000");

        expect(
            actualSecondExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - two calculations - Decimals 18", async () => {
        //given
        const alfa = P_01_DEC18;

        const firstLastExponentialWeightedMovingVariance = BigNumber.from("13479210000000000");
        const firstExponentialMovingAverage = P_0005_DEC18;
        const firstIndexValue = P_005_DEC18;

        //first calculation
        const actualFirstExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                firstLastExponentialWeightedMovingVariance,
                firstExponentialMovingAverage,
                firstIndexValue,
                alfa
            );

        const secondLastExponentialWeightedMovingVariance =
            actualFirstExponentialWeightedMovingVariance;
        const secondExponentialMovingAverage = BigNumber.from("10500000000000000");
        const secondIndexValue = P_006_DEC18;

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
        const expectedExponentialWeightedMovingVariance = BigNumber.from("373539600000000");

        expect(
            actualSecondExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - IPOR Index < EMA (Exponential Moving Average) - Decimals 18", async () => {
        //given
        const alfa = P_01_DEC18;

        const lastExponentialWeightedMovingVariance = BigNumber.from("13479210000000000");
        const exponentialMovingAverage = P_0005_DEC18;
        const indexValue = P_0004_DEC18;

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigNumber.from("1348011000000000");

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - IPOR Index = EMA (Exponential Moving Average) - Decimals 18", async () => {
        //given
        const alfa = P_01_DEC18;

        const lastExponentialWeightedMovingVariance = BigNumber.from("13479210000000000");
        const exponentialMovingAverage = P_0005_DEC18;
        const indexValue = P_0005_DEC18;

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigNumber.from("1347921000000000");

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should calculate Exponential Weighted Moving Variance - IPOR Index > EMA (Exponential Moving Average), Alfa = 0 - Decimals 18", async () => {
        //given
        const alfa = ZERO;

        const lastExponentialWeightedMovingVariance = BigNumber.from("13479210000000000");
        const exponentialMovingAverage = P_0005_DEC18;
        const indexValue = P_0006_DEC18;

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
        const alfa = ONE_18DEC;

        const lastExponentialWeightedMovingVariance = BigNumber.from("13479210000000000");
        const exponentialMovingAverage = P_0005_DEC18;
        const indexValue = P_0006_DEC18;

        //when
        const actualExponentialWeightedMovingVariance =
            await iporLogic.calculateExponentialWeightedMovingVariance(
                lastExponentialWeightedMovingVariance,
                exponentialMovingAverage,
                indexValue,
                alfa
            );

        //then
        const expectedExponentialWeightedMovingVariance = BigNumber.from("13479210000000000");

        expect(
            actualExponentialWeightedMovingVariance,
            "Incorrect Exponential Weighted Moving Variance"
        ).to.be.equal(expectedExponentialWeightedMovingVariance);
    });

    it("Should NOT calculate Exponential Weighted Moving Variance - EMVar (Exponential Weighted Moving Variance) > 1 - Decimals 18", async () => {
        //given
        const alfa = BigNumber.from("250000000000000000");

        const lastExponentialWeightedMovingVariance = ONE_18DEC;
        const exponentialMovingAverage = ONE_18DEC;
        const indexValue = BigNumber.from("4").mul(ONE_18DEC);

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
        const alfa = BigNumber.from("1000000000000000001");

        const lastExponentialWeightedMovingVariance = ZERO;
        const exponentialMovingAverage = BigNumber.from("113000000000000000");
        const indexValue = P_05_DEC18;

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
