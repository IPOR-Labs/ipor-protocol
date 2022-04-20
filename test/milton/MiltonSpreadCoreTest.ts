import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N1__0_18DEC,
    N0__01_18DEC,
    N0__001_18DEC,
    N0__000_01_18DEC,
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
        const dcMaxLiquidityRedemptionValue = await miltonSpread.getDCMaxLiquidityRedemptionValue();
        const b1 = await miltonSpread.getB1();
        const b2 = await miltonSpread.getB2();
        const v1 = await miltonSpread.getV1();
        const v2 = await miltonSpread.getV2();
        const m1 = await miltonSpread.getM1();
        const m2 = await miltonSpread.getM2();

        // then
        expect(spreadPremiumsMaxValue).to.be.equal(BigNumber.from("3").mul(N0__001_18DEC));
        expect(dCKfValue).to.be.equal(N0__000_01_18DEC);
        expect(dCLambdaValue).to.be.equal(N0__01_18DEC);
        expect(dCKOmegaValue).to.be.equal(BigNumber.from("5").mul(N0__000_01_18DEC));
        expect(dcMaxLiquidityRedemptionValue).to.be.equal(N1__0_18DEC);
        expect(b1).to.be.equal(BigNumber.from("-8260047328466268"));
        expect(b2).to.be.equal(BigNumber.from("-9721941081703882"));
        expect(v1).to.be.equal(BigNumber.from("47294930726988593"));
        expect(v2).to.be.equal(BigNumber.from("8792990351805524"));
        expect(m1).to.be.equal(BigNumber.from("-9721941081703882"));
        expect(m2).to.be.equal(BigNumber.from("-3996501128463404"));
    });
});
