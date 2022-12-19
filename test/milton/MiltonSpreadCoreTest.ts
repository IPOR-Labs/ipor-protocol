import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    prepareMiltonSpreadBaseDai,
    prepareMiltonSpreadBaseUsdt,
    prepareMiltonSpreadBaseUsdc,
} from "../utils/MiltonUtils";

import { assertError } from "../utils/AssertUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Core", () => {
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
    });

    it("Should return proper constant for USDT", async () => {
        // given
        const miltonSpread = await prepareMiltonSpreadBaseUsdt();

        // when
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
        expect(payFixedRegionOneBase).to.be.equal(BigNumber.from("52734899"));

        expect(payFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("14420251537169199104")
        );

        expect(payFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-1242450165256140032")
        );

        expect(payFixedRegionTwoBase).to.be.equal(BigNumber.from("0"));

        expect(payFixedRegionTwoSlopeForVolatility).to.be.equal(BigNumber.from("91"));

        expect(payFixedRegionTwoSlopeForMeanReversion).to.be.equal(BigNumber.from("-3"));

        expect(receiveFixedRegionOneBase).to.be.equal(BigNumber.from("-653622053554807"));

        expect(receiveFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("879558312553575296")
        );

        expect(receiveFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("54807065624269344")
        );

        expect(receiveFixedRegionTwoBase).to.be.equal(BigNumber.from("-884495153628362"));

        expect(receiveFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("175497432169175456")
        );

        expect(receiveFixedRegionTwoSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-995660609325833088")
        );
    });

    it("Should return proper constant for USDC", async () => {
        // given
        const miltonSpread = await prepareMiltonSpreadBaseUsdc();

        // when
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
        expect(payFixedRegionOneBase).to.be.equal(BigNumber.from("246221635508210"));

        expect(payFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("7175545968273476608")
        );

        expect(payFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-998967008815501824")
        );

        expect(payFixedRegionTwoBase).to.be.equal(BigNumber.from("250000000000000"));

        expect(payFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("600000002394766180352")
        );

        expect(payFixedRegionTwoSlopeForMeanReversion).to.be.equal(BigNumber.from("0"));

        expect(receiveFixedRegionOneBase).to.be.equal(BigNumber.from("-250000000201288"));

        expect(receiveFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("-2834673328995")
        );

        expect(receiveFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("999999997304907264")
        );

        expect(receiveFixedRegionTwoBase).to.be.equal(BigNumber.from("-250000000000000"));

        expect(receiveFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("-600000000289261748224")
        );

        expect(receiveFixedRegionTwoSlopeForMeanReversion).to.be.equal(BigNumber.from("0"));
    });

    it("Should return proper constant for DAI", async () => {
        // given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        // when
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
        expect(payFixedRegionOneBase).to.be.equal(BigNumber.from("313550690114778"));
        expect(payFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("5881342150134894592")
        );
        expect(payFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-1067399359265083392")
        );
        expect(payFixedRegionTwoBase).to.be.equal(BigNumber.from("250000000000000"));
        expect(payFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("600000001445265276928")
        );
        expect(payFixedRegionTwoSlopeForMeanReversion).to.be.equal(BigNumber.from("0"));
        expect(receiveFixedRegionOneBase).to.be.equal(BigNumber.from("-250000000349912"));
        expect(receiveFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("-1961227517387")
        );
        expect(receiveFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("999999997838885760")
        );
        expect(receiveFixedRegionTwoBase).to.be.equal(BigNumber.from("-250000000000000"));
        expect(receiveFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("-600000001299204145152")
        );
        expect(receiveFixedRegionTwoSlopeForMeanReversion).to.be.equal(BigNumber.from("0"));
    });
});
