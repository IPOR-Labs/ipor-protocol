import hre from "hardhat";
import chai from "chai";
import { ItfMiltonSpreadModelDai } from "../../types";
import { N0__01_18DEC } from "../utils/Constants";
const { expect } = chai;

describe("ITF MiltonSpreadModel", () => {
    let miltonSpreadModelDai: ItfMiltonSpreadModelDai;

    beforeEach(async () => {
        const MockSpreadModel = await hre.ethers.getContractFactory("ItfMiltonSpreadModelDai");
        miltonSpreadModelDai = (await MockSpreadModel.deploy()) as ItfMiltonSpreadModelDai;
    });

    it("should check if setup method works, DAI", async () => {
        // given
        const payFixedRegionOneBaseBefore = await miltonSpreadModelDai.getPayFixedRegionOneBase();
        const payFixedRegionOneSlopeForVolatilityBefore =
            await miltonSpreadModelDai.getPayFixedRegionOneSlopeForVolatility();
        const payFixedRegionOneSlopeForMeanReversionBefore =
            await miltonSpreadModelDai.getPayFixedRegionOneSlopeForMeanReversion();
        const payFixedRegionTwoBaseBefore = await miltonSpreadModelDai.getPayFixedRegionTwoBase();
        const payFixedRegionTwoSlopeForVolatilityBefore =
            await miltonSpreadModelDai.getPayFixedRegionTwoSlopeForVolatility();
        const payFixedRegionTwoSlopeForMeanReversionBefore =
            await miltonSpreadModelDai.getPayFixedRegionTwoSlopeForMeanReversion();
        const receiveFixedRegionOneBaseBefore =
            await miltonSpreadModelDai.getReceiveFixedRegionOneBase();
        const receiveFixedRegionOneSlopeForVolatilityBefore =
            await miltonSpreadModelDai.getReceiveFixedRegionOneSlopeForVolatility();
        const receiveFixedRegionOneSlopeForMeanReversionBefore =
            await miltonSpreadModelDai.getReceiveFixedRegionOneSlopeForMeanReversion();
        const receiveFixedRegionTwoBaseBefore =
            await miltonSpreadModelDai.getReceiveFixedRegionTwoBase();
        const receiveFixedRegionTwoSlopeForVolatilityBefore =
            await miltonSpreadModelDai.getReceiveFixedRegionTwoSlopeForVolatility();
        const receiveFixedRegionTwoSlopeForMeanReversionBefore =
            await miltonSpreadModelDai.getReceiveFixedRegionTwoSlopeForMeanReversion();

        // when
        await miltonSpreadModelDai.setupModelParams(
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
        const payFixedRegionOneBaseAfter = await miltonSpreadModelDai.getPayFixedRegionOneBase();
        const payFixedRegionOneSlopeForVolatilityAfter =
            await miltonSpreadModelDai.getPayFixedRegionOneSlopeForVolatility();
        const payFixedRegionOneSlopeForMeanReversionAfter =
            await miltonSpreadModelDai.getPayFixedRegionOneSlopeForMeanReversion();
        const payFixedRegionTwoBaseAfter = await miltonSpreadModelDai.getPayFixedRegionTwoBase();
        const payFixedRegionTwoSlopeForVolatilityAfter =
            await miltonSpreadModelDai.getPayFixedRegionTwoSlopeForVolatility();
        const payFixedRegionTwoSlopeForMeanReversionAfter =
            await miltonSpreadModelDai.getPayFixedRegionTwoSlopeForMeanReversion();
        const receiveFixedRegionOneBaseAfter =
            await miltonSpreadModelDai.getReceiveFixedRegionOneBase();
        const receiveFixedRegionOneSlopeForVolatilityAfter =
            await miltonSpreadModelDai.getReceiveFixedRegionOneSlopeForVolatility();
        const receiveFixedRegionOneSlopeForMeanReversionAfter =
            await miltonSpreadModelDai.getReceiveFixedRegionOneSlopeForMeanReversion();
        const receiveFixedRegionTwoBaseAfter =
            await miltonSpreadModelDai.getReceiveFixedRegionTwoBase();
        const receiveFixedRegionTwoSlopeForVolatilityAfter =
            await miltonSpreadModelDai.getReceiveFixedRegionTwoSlopeForVolatility();
        const receiveFixedRegionTwoSlopeForMeanReversionAfter =
            await miltonSpreadModelDai.getReceiveFixedRegionTwoSlopeForMeanReversion();

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
