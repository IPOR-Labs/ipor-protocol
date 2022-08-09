import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockBaseMiltonSpreadModelDai } from "../../types";
import { prepareMockMiltonSpreadModelDai, prepareMiltonSpreadBaseDai } from "../utils/MiltonUtils";

import { assertError } from "../utils/AssertUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Core", () => {
    let miltonSpreadModel: MockBaseMiltonSpreadModelDai;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModelDai();
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();
        const expectedNewOwner = userTwo;

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonSpread.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await miltonSpread.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            miltonSpread.connect(userThree).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();
        const expectedNewOwner = userTwo;

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await assertError(
            miltonSpread.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();
        const expectedNewOwner = userTwo;

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonSpread.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            miltonSpread.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();
        const expectedNewOwner = userTwo;

        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonSpread.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const expectedNewOwner = userTwo;

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await miltonSpread.connect(userOne).owner();
        expect(await admin.getAddress()).to.be.equal(actualNewOwner);
    });

    it("Should return proper constant", async () => {
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
        expect(payFixedRegionOneBase).to.be.equal(BigNumber.from("44525308187"));
        expect(payFixedRegionOneSlopeForVolatility).to.be.equal(BigNumber.from("7295029327499250688"));
        expect(payFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("1957606734120302592")
        );
        expect(payFixedRegionTwoBase).to.be.equal(BigNumber.from("2805894176280989"));
        expect(payFixedRegionTwoSlopeForVolatility).to.be.equal(BigNumber.from("60862801283727532032"));
        expect(payFixedRegionTwoSlopeForMeanReversion).to.be.equal(
            BigNumber.from("814944608049619968")
        );
        expect(receiveFixedRegionOneBase).to.be.equal(BigNumber.from("-155830648166213"));
        expect(receiveFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("21718204087089586176")
        );
        expect(receiveFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-1067938568082170880")
        );
        expect(receiveFixedRegionTwoBase).to.be.equal(BigNumber.from("-5807404091"));
        expect(receiveFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("12842479402900596736")
        );
        expect(receiveFixedRegionTwoSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-1078905683664530048")
        );
    });
});
