const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");
const { utils } = require("web3");

const {
    USD_20_18DEC,
    USD_2_000_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_14_000_18DEC,
    ZERO,
} = require("./Const.js");

const {
    prepareData,
    prepareMiltonSpreadBase,
    prepareMiltonSpreadCase2,
    prepareMiltonSpreadCase3,
    prepareMiltonSpreadCase4,
    prepareMiltonSpreadCase5,
} = require("./Utils");

describe("MiltonSpreadModel - Core", () => {
    let data = null;
    let admin, userOne, userTwo, userThree, liquidityProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            1
        );
    });
    it("should init config with ", async () => {});
    it("should calculate Adjusted Utilization Rate - simple case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigInt("480000000000000000");
        const utilizationRateLegWithoutSwap = BigInt("480000000000000000");
        const lambda = BigInt("10000000000000000");

        const expectedAdjustedUtilizationRate = BigInt("480000000000000000");
        //when
        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(
            actualAdjustedUtilizationRate
        );
    });

    it("should calculate Adjusted Utilization Rate - UR with Swap > UR without Swap", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigInt("500000000000000000");
        const utilizationRateLegWithoutSwap = BigInt("400000000000000000");
        const lambda = BigInt("10000000000000000");

        const expectedAdjustedUtilizationRate = BigInt("500000000000000000");
        //when
        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(
            actualAdjustedUtilizationRate
        );
    });

    it("should calculate Adjusted Utilization Rate - UR with Swap < UR without Swap", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigInt("400000000000000000");
        const utilizationRateLegWithoutSwap = BigInt("500000000000000000");
        const lambda = BigInt("10000000000000000");

        const expectedAdjustedUtilizationRate = BigInt("399000000000000000");
        //when
        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(
            actualAdjustedUtilizationRate
        );
    });

    it("should calculate Adjusted Utilization Rate - UR with Swap = 0 and UR without Swap = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigInt("0");
        const utilizationRateLegWithoutSwap = BigInt("0");
        const lambda = BigInt("10000000000000000");

        const expectedAdjustedUtilizationRate = BigInt("0");
        //when
        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(
            actualAdjustedUtilizationRate
        );
    });

    it("should calculate Adjusted Utilization Rate - Imbalance Factor < UR with Swap", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigInt("480000000000000000");
        const utilizationRateLegWithoutSwap = BigInt("990000000000000000");
        const lambda = BigInt("10000000000000000");

        const expectedAdjustedUtilizationRate = BigInt("474900000000000000");

        //when
        let actualAdjustedUtilizationRate = BigInt(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(
            actualAdjustedUtilizationRate
        );
    });
});
