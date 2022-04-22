import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { N1__0_18DEC, N0__01_18DEC, N0__001_18DEC, N0__000_01_18DEC } from "../utils/Constants";
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
        const payFixedRegionOneBase = await miltonSpread.getPayFixedRegionOneBase();
        const payFixedRegionOneSlopeForVolatility =
            await miltonSpread.getPayFixedRegionOneSlopeForVolatility();
        const payFixedRegionOneSlopeForMeanReversion =
            await miltonSpread.getPayFixedRegionOneSlopeForMeanReversion();
        const payFixedRegionTwoBase = await miltonSpread.getPayFixedRegionTwoBase();
        const payFixedRegionTwoSlopeForVolatility =
            await miltonSpread.getPayFixedRegionTwoSlopeForVolatility();
        const payFixedRegionTwoSlopeForMeanReversion =
            await miltonSpread.getPayFixedRegionTwoSlopeForMeanReversion();
        const receiveFixedRegionOneBase = await miltonSpread.getReceiveFixedRegionOneBase();
        const receiveFixedRegionOneSlopeForVolatility =
            await miltonSpread.getReceiveFixedRegionOneSlopeForVolatility();
        const receiveFixedRegionOneSlopeForMeanReversion =
            await miltonSpread.getReceiveFixedRegionOneSlopeForMeanReversion();
        const receiveFixedRegionTwoBase = await miltonSpread.getReceiveFixedRegionTwoBase();
        const receiveFixedRegionTwoSlopeForVolatility =
            await miltonSpread.getReceiveFixedRegionTwoSlopeForVolatility();
        const receiveFixedRegionTwoSlopeForMeanReversion =
            await miltonSpread.getReceiveFixedRegionTwoSlopeForMeanReversion();

        // then
        expect(spreadPremiumsMaxValue).to.be.equal(BigNumber.from("3").mul(N0__001_18DEC));
        expect(dCKfValue).to.be.equal(N0__000_01_18DEC);
        expect(dCLambdaValue).to.be.equal(N0__01_18DEC);
        expect(dCKOmegaValue).to.be.equal(BigNumber.from("5").mul(N0__000_01_18DEC));
        expect(dcMaxLiquidityRedemptionValue).to.be.equal(N1__0_18DEC);
        expect(payFixedRegionOneBase).to.be.equal(BigNumber.from("1570169440701153"));
        expect(payFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("198788881093494850")
        );
        expect(payFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-38331366057144010")
        );
        expect(payFixedRegionTwoBase).to.be.equal(BigNumber.from("5957385912947852"));
        expect(payFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("422085481190794900")
        );
        expect(payFixedRegionTwoSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-1044585377149331200")
        );
        expect(receiveFixedRegionOneBase).to.be.equal(BigNumber.from("237699618248427"));
        expect(receiveFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("35927957683456455")
        );
        expect(receiveFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("10158530403206013")
        );
        expect(receiveFixedRegionTwoBase).to.be.equal(BigNumber.from("-493406136001736"));
        expect(receiveFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("-2696690872084165600")
        );
        expect(receiveFixedRegionTwoSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-923865786926514900")
        );
    });
});
