const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
    assertError,
    prepareData,
    prepareTestData,
    getLibraries,
} = require("./Utils");

const { USD_10_000_18DEC } = require("./Const.js");
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

    it("Accrue Ibt Price Decimals 18", async () => {
        //given
        const initialTimestamp = BigInt(Date.now());
        const initialQuasiIbtPrice = ONE_18DEC * YEAR_IN_SECONDS;

        const ipor = {
            asset: admin.address,
            indexValue: BigInt("30000000000000000"),
            quasiIbtPrice: initialQuasiIbtPrice,
            exponentialMovingAverage: BigInt("30000000000000000"),
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

    it("Accrue IbtPrice Two Calculations Decimals18", async () => {
        //given
        const initialTimestamp = BigInt(Date.now());
        const initialQuasiIbtPrice = ONE_18DEC * YEAR_IN_SECONDS;

        const ipor = {
            asset: admin.address,
            indexValue: BigInt("30000000000000000"),
            quasiIbtPrice: initialQuasiIbtPrice,
            exponentialMovingAverage: BigInt("30000000000000000"),
            blockTimestamp: initialTimestamp,
        };

        const days25 = BigInt(60 * 60 * 24 * 25);

        const firstCalculationTimestamp = initialTimestamp + days25;
        await iporLogic.accrueQuasiIbtPrice(ipor, firstCalculationTimestamp);

        const secondCalculationTimestamp = firstCalculationTimestamp + days25;

        const expectedIbtPrice = BigInt("1004109589041095890");

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

    it("Calculate Exponential Moving Average Two Calculations Decimals 18", async () => {
        //given
        const exponentialMovingAverage = BigInt("30000000000000000");
        const indexValue = BigInt("50000000000000000");
        const decayFactor = BigInt("10000000000000000");
        const expectedExponentialMovingAverage = "30200000000000000";

        //when
        const actualExponentialMovingAverage =
            await iporLogic.calculateExponentialMovingAverage(
                exponentialMovingAverage,
                indexValue,
                decayFactor
            );

        //then
        expect(
            actualExponentialMovingAverage,
            "Incorrect Exponential Moving Average"
        ).to.be.equal(expectedExponentialMovingAverage);
    });
});
