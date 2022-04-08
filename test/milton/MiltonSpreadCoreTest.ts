import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N0__01_18DEC,
    N0__001_18DEC,
    N0__000_1_18DEC,
    N0__000_01_18DEC,
    N0__000_001_18DEC,
    ZERO,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    prepareMiltonSpreadBase,
} from "../utils/MiltonUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Core", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should calculate Adjusted Utilization Rate - simple case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigNumber.from("48").mul(N0__01_18DEC);
        const utilizationRateLegWithoutSwap = BigNumber.from("48").mul(N0__01_18DEC);
        const lambda = BigNumber.from("1").mul(N0__01_18DEC);

        const expectedAdjustedUtilizationRate = BigNumber.from("48").mul(N0__01_18DEC);
        //when
        let actualAdjustedUtilizationRate = BigNumber.from(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(actualAdjustedUtilizationRate);
    });

    it("should calculate Adjusted Utilization Rate - UR with Swap > UR without Swap", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigNumber.from("50").mul(N0__01_18DEC);
        const utilizationRateLegWithoutSwap = BigNumber.from("40").mul(N0__01_18DEC);
        const lambda = BigNumber.from("1").mul(N0__01_18DEC);

        const expectedAdjustedUtilizationRate = BigNumber.from("50").mul(N0__01_18DEC);
        //when
        let actualAdjustedUtilizationRate = BigNumber.from(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(actualAdjustedUtilizationRate);
    });

    it("should calculate Adjusted Utilization Rate - UR with Swap < UR without Swap", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigNumber.from("40").mul(N0__01_18DEC);
        const utilizationRateLegWithoutSwap = BigNumber.from("50").mul(N0__01_18DEC);
        const lambda = BigNumber.from("1").mul(N0__01_18DEC);

        const expectedAdjustedUtilizationRate = BigNumber.from("399000000000000000");
        //when
        let actualAdjustedUtilizationRate = BigNumber.from(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(actualAdjustedUtilizationRate);
    });

    it("should calculate Adjusted Utilization Rate - UR with Swap = 0 and UR without Swap = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigNumber.from("0");
        const utilizationRateLegWithoutSwap = BigNumber.from("0");
        const lambda = BigNumber.from("1").mul(N0__01_18DEC);

        const expectedAdjustedUtilizationRate = BigNumber.from("0");
        //when
        let actualAdjustedUtilizationRate = BigNumber.from(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(actualAdjustedUtilizationRate);
    });

    it("should calculate Adjusted Utilization Rate - Imbalance Factor < UR with Swap", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const utilizationRateLegWithSwap = BigNumber.from("48").mul(N0__01_18DEC);
        const utilizationRateLegWithoutSwap = BigNumber.from("99").mul(N0__01_18DEC);
        const lambda = BigNumber.from("1").mul(N0__01_18DEC);

        const expectedAdjustedUtilizationRate = BigNumber.from("474900000000000000");

        //when
        let actualAdjustedUtilizationRate = BigNumber.from(
            await miltonSpread
                .connect(liquidityProvider)
                .testCalculateAdjustedUtilizationRate(
                    utilizationRateLegWithSwap,
                    utilizationRateLegWithoutSwap,
                    lambda
                )
        );

        //then
        expect(expectedAdjustedUtilizationRate).to.be.eq(actualAdjustedUtilizationRate);
    });

    it("Should return proper constant", async () => {
        // given
        const miltonSpread = await prepareMiltonSpreadBase();

        // when

        const spreadPremiumsMaxValue = await miltonSpread.getSpreadPremiumsMaxValue();
        const dCKfValue = await miltonSpread.getDCKfValue();
        const dCLambdaValue = await miltonSpread.getDCLambdaValue();
        const dCKOmegaValue = await miltonSpread.getDCKOmegaValue();
        const atParComponentKVolValue = await miltonSpread.getAtParComponentKVolValue();
        const atParComponentKHistValue = await miltonSpread.getAtParComponentKHistValue();

        // then

        expect(spreadPremiumsMaxValue).to.be.equal(BigNumber.from("3").mul(N0__001_18DEC));
        expect(dCKfValue).to.be.equal(N0__000_01_18DEC);
        expect(dCLambdaValue).to.be.equal(N0__01_18DEC);
        expect(dCKOmegaValue).to.be.equal(BigNumber.from("5").mul(N0__000_01_18DEC));
        expect(atParComponentKVolValue).to.be.equal(ZERO);
        expect(atParComponentKHistValue).to.be.equal(BigNumber.from("3").mul(N0__000_1_18DEC));
    });
});
