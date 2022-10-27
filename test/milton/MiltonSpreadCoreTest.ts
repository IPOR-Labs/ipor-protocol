import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { prepareMiltonSpreadBaseDai } from "../utils/MiltonUtils";

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
        expect(payFixedRegionOneBase).to.be.equal(BigNumber.from("223452028860278"));
        expect(payFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("66176612458519781376")
        );
        expect(payFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-1186134254033851648")
        );
        expect(payFixedRegionTwoBase).to.be.equal(BigNumber.from("145660962344800"));
        expect(payFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("213838820626510938112")
        );
        expect(payFixedRegionTwoSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-963243845920214784")
        );
        expect(receiveFixedRegionOneBase).to.be.equal(BigNumber.from("-86557160865515"));
        expect(receiveFixedRegionOneSlopeForVolatility).to.be.equal(
            BigNumber.from("-37390455427043344384")
        );
        expect(receiveFixedRegionOneSlopeForMeanReversion).to.be.equal(
            BigNumber.from("-1129730689647621632")
        );
        expect(receiveFixedRegionTwoBase).to.be.equal(BigNumber.from("-55994330424481"));
        expect(receiveFixedRegionTwoSlopeForVolatility).to.be.equal(
            BigNumber.from("-89741154814986338304")
        );
        expect(receiveFixedRegionTwoSlopeForMeanReversion).to.be.equal(
            BigNumber.from("37480678662666200")
        );
    });
});
