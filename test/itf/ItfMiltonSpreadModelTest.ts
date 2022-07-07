import hre from "hardhat";
import chai from "chai";
import { ItfMiltonSpreadModel } from "../../types";
import { N0__01_18DEC } from "../utils/Constants";
const { expect } = chai;

describe("MiltonSpreadRecFixed", () => {
    let miltonSpreadModel: ItfMiltonSpreadModel;

    beforeEach(async () => {
        const MockSpreadModel = await hre.ethers.getContractFactory("ItfMiltonSpreadModel");
        miltonSpreadModel = (await MockSpreadModel.deploy()) as ItfMiltonSpreadModel;
    });

    it("tst", async () => {
        // given
        const payFixedRegionOneBaseBefore = await miltonSpreadModel.getPayFixedRegionOneBase();
        const payFixedRegionOneSlopeForVolatilityBefore =
            await miltonSpreadModel.getPayFixedRegionOneSlopeForVolatility();
        const payFixedRegionOneSlopeForMeanReversionBefore =
            await miltonSpreadModel.getPayFixedRegionOneSlopeForMeanReversion();
        const payFixedRegionTwoBaseBefore = await miltonSpreadModel.getPayFixedRegionTwoBase();
        const payFixedRegionTwoSlopeForVolatilityBefore =
            await miltonSpreadModel.getPayFixedRegionTwoSlopeForVolatility();
        const payFixedRegionTwoSlopeForMeanReversionBefore =
            await miltonSpreadModel.getPayFixedRegionTwoSlopeForMeanReversion();
        const receiveFixedRegionOneBaseBefore =
            await miltonSpreadModel.getReceiveFixedRegionOneBase();
        const receiveFixedRegionOneSlopeForVolatilityBefore =
            await miltonSpreadModel.getReceiveFixedRegionOneSlopeForVolatility();
        const receiveFixedRegionOneSlopeForMeanReversionBefore =
            await miltonSpreadModel.getReceiveFixedRegionOneSlopeForMeanReversion();
        const receiveFixedRegionTwoBaseBefore =
            await miltonSpreadModel.getReceiveFixedRegionTwoBase();
        const receiveFixedRegionTwoSlopeForVolatilityBefore =
            await miltonSpreadModel.getReceiveFixedRegionTwoSlopeForVolatility();
        const receiveFixedRegionTwoSlopeForMeanReversionBefore =
            await miltonSpreadModel.getReceiveFixedRegionTwoSlopeForMeanReversion();

        // when
        await miltonSpreadModel.setupModelParams(
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC,
            N0__01_18DEC
        );
        // then
        const payFixedRegionOneBaseAfter = await miltonSpreadModel.getPayFixedRegionOneBase();
        const payFixedRegionOneSlopeForVolatilityAfter =
            await miltonSpreadModel.getPayFixedRegionOneSlopeForVolatility();
        const payFixedRegionOneSlopeForMeanReversionAfter =
            await miltonSpreadModel.getPayFixedRegionOneSlopeForMeanReversion();
        const payFixedRegionTwoBaseAfter = await miltonSpreadModel.getPayFixedRegionTwoBase();
        const payFixedRegionTwoSlopeForVolatilityAfter =
            await miltonSpreadModel.getPayFixedRegionTwoSlopeForVolatility();
        const payFixedRegionTwoSlopeForMeanReversionAfter =
            await miltonSpreadModel.getPayFixedRegionTwoSlopeForMeanReversion();
        const receiveFixedRegionOneBaseAfter =
            await miltonSpreadModel.getReceiveFixedRegionOneBase();
        const receiveFixedRegionOneSlopeForVolatilityAfter =
            await miltonSpreadModel.getReceiveFixedRegionOneSlopeForVolatility();
        const receiveFixedRegionOneSlopeForMeanReversionAfter =
            await miltonSpreadModel.getReceiveFixedRegionOneSlopeForMeanReversion();
        const receiveFixedRegionTwoBaseAfter =
            await miltonSpreadModel.getReceiveFixedRegionTwoBase();
        const receiveFixedRegionTwoSlopeForVolatilityAfter =
            await miltonSpreadModel.getReceiveFixedRegionTwoSlopeForVolatility();
        const receiveFixedRegionTwoSlopeForMeanReversionAfter =
            await miltonSpreadModel.getReceiveFixedRegionTwoSlopeForMeanReversion();

        expect(payFixedRegionOneBaseBefore).to.be.not.equal(N0__01_18DEC);
        expect(payFixedRegionOneSlopeForVolatilityBefore).to.be.not.equal(N0__01_18DEC);
        expect(payFixedRegionOneSlopeForMeanReversionBefore).to.be.not.equal(N0__01_18DEC);
        expect(payFixedRegionTwoBaseBefore).to.be.not.equal(N0__01_18DEC);
        expect(payFixedRegionTwoSlopeForVolatilityBefore).to.be.not.equal(N0__01_18DEC);
        expect(payFixedRegionTwoSlopeForMeanReversionBefore).to.be.not.equal(N0__01_18DEC);
        expect(receiveFixedRegionOneBaseBefore).to.be.not.equal(N0__01_18DEC);
        expect(receiveFixedRegionOneSlopeForVolatilityBefore).to.be.not.equal(N0__01_18DEC);
        expect(receiveFixedRegionOneSlopeForMeanReversionBefore).to.be.not.equal(N0__01_18DEC);
        expect(receiveFixedRegionTwoBaseBefore).to.be.not.equal(N0__01_18DEC);
        expect(receiveFixedRegionTwoSlopeForVolatilityBefore).to.be.not.equal(N0__01_18DEC);
        expect(receiveFixedRegionTwoSlopeForMeanReversionBefore).to.be.not.equal(N0__01_18DEC);

        expect(payFixedRegionOneBaseAfter).to.be.equal(N0__01_18DEC);
        expect(payFixedRegionOneSlopeForVolatilityAfter).to.be.equal(N0__01_18DEC);
        expect(payFixedRegionOneSlopeForMeanReversionAfter).to.be.equal(N0__01_18DEC);
        expect(payFixedRegionTwoBaseAfter).to.be.equal(N0__01_18DEC);
        expect(payFixedRegionTwoSlopeForVolatilityAfter).to.be.equal(N0__01_18DEC);
        expect(payFixedRegionTwoSlopeForMeanReversionAfter).to.be.equal(N0__01_18DEC);
        expect(receiveFixedRegionOneBaseAfter).to.be.equal(N0__01_18DEC);
        expect(receiveFixedRegionOneSlopeForVolatilityAfter).to.be.equal(N0__01_18DEC);
        expect(receiveFixedRegionOneSlopeForMeanReversionAfter).to.be.equal(N0__01_18DEC);
        expect(receiveFixedRegionTwoBaseAfter).to.be.equal(N0__01_18DEC);
        expect(receiveFixedRegionTwoSlopeForVolatilityAfter).to.be.equal(N0__01_18DEC);
        expect(receiveFixedRegionTwoSlopeForMeanReversionAfter).to.be.equal(N0__01_18DEC);
    });
});
