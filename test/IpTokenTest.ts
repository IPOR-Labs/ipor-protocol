import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { IpToken, DaiMockedToken, MockSpreadModel } from "../types";
import { PERCENTAGE_3_18DEC, TC_TOTAL_AMOUNT_10_000_18DEC, ZERO } from "./utils/Constants";

import { assertError } from "./utils/AssertUtils";
import { prepareTestData } from "./utils/DataUtils";
import {
    prepareMockSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "./utils/MiltonUtils";
import {
    JosephUsdcMockCases,
    JosephUsdtMockCases,
    JosephDaiMockCases,
    JosephDaiMocks,
} from "./utils/JosephUtils";
import { MockStanleyCase } from "./utils/StanleyUtils";

const { expect } = chai;

describe("IpToken", () => {
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;
    let miltonSpreadModel: MockSpreadModel; //data

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockSpreadModel(ZERO, ZERO, ZERO, ZERO);
    });

    const preperateIpTokenCase010 = async (): Promise<{
        ipToken: IpToken;
        josephDai: JosephDaiMocks;
        tokenDai: DaiMockedToken;
    }> => {
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const { ipTokenDai, josephDai, tokenDai } = testData;
        if (ipTokenDai === undefined || josephDai === undefined || tokenDai === undefined) {
            throw new Error("Setup IpToken Error");
        } else {
            return { ipToken: ipTokenDai, josephDai, tokenDai };
        }
    };

    const preperateIpTokenCase110 = async (): Promise<{
        ipToken: IpToken;
        josephDai: JosephDaiMocks;
    }> => {
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE1,
            MiltonUsdtCase.CASE1,
            MiltonDaiCase.CASE1,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const { ipTokenDai, josephDai } = testData;
        if (ipTokenDai === undefined || josephDai === undefined) {
            throw new Error("Setup IpToken Error");
        } else {
            return { ipToken: ipTokenDai, josephDai };
        }
    };

    it("should transfer ownership - simple case 1", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { ipToken } = await preperateIpTokenCase010();

        //when
        await ipToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());
        await ipToken.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await ipToken.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { ipToken } = await preperateIpTokenCase010();

        //when
        await assertError(
            ipToken.connect(userThree).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { ipToken } = await preperateIpTokenCase010();

        //when
        await ipToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());
        await assertError(
            ipToken.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { ipToken } = await preperateIpTokenCase010();

        //when
        await ipToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());
        await ipToken.connect(expectedNewOwner).confirmTransferOwnership();
        await assertError(ipToken.connect(expectedNewOwner).confirmTransferOwnership(), "IPOR_007");
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { ipToken } = await preperateIpTokenCase110();

        await ipToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());
        await ipToken.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            ipToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { ipToken } = await preperateIpTokenCase110();

        await ipToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //when
        await ipToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await ipToken.connect(userOne).owner();

        expect(await admin.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should NOT mint ipToken if not a Joseph", async () => {
        //given
        const { ipToken } = await preperateIpTokenCase110();

        //when
        await assertError(
            //when
            ipToken.connect(userTwo).mint(await userOne.getAddress(), TC_TOTAL_AMOUNT_10_000_18DEC),
            //then
            "IPOR_325"
        );
    });

    it("should NOT mint ipToken if Zero", async () => {
        //given
        const { ipToken } = await preperateIpTokenCase110();
        await ipToken.setJoseph(await admin.getAddress());
        //when
        await assertError(
            //when
            ipToken.mint(await userOne.getAddress(), ZERO),
            //then
            "IPOR_400"
        );
    });

    it("should NOT burn ipToken if Zero", async () => {
        //given
        const { ipToken } = await preperateIpTokenCase110();
        await ipToken.setJoseph(await admin.getAddress());
        //when
        await assertError(
            //when
            ipToken.burn(await userOne.getAddress(), ZERO),
            //then
            "IPOR_401"
        );
    });

    it("should NOT burn ipToken if not a Joseph", async () => {
        //when
        const { ipToken } = await preperateIpTokenCase110();

        await assertError(
            //when
            ipToken.connect(userTwo).burn(await userOne.getAddress(), TC_TOTAL_AMOUNT_10_000_18DEC),
            //then
            "IPOR_325"
        );
    });

    it("should emit event", async () => {
        //given
        const { ipToken, josephDai } = await preperateIpTokenCase010();
        await ipToken.setJoseph(await admin.getAddress());
        //when
        await expect(ipToken.mint(await userOne.getAddress(), TC_TOTAL_AMOUNT_10_000_18DEC))
            .to.emit(ipToken, "Mint")
            .withArgs(await userOne.getAddress(), TC_TOTAL_AMOUNT_10_000_18DEC);

        await ipToken.setJoseph(josephDai.address);
    });

    it("should contain 18 decimals", async () => {
        //given
        const { ipToken, josephDai } = await preperateIpTokenCase010();
        const expectedDecimals = BigNumber.from("18");

        await ipToken.setJoseph(await admin.getAddress());
        //when
        const actualDecimals = await ipToken.decimals();

        //then
        expect(
            expectedDecimals,
            `Incorrect decimals actual: ${actualDecimals}, expected: ${expectedDecimals}`
        ).to.be.equal(actualDecimals);

        await ipToken.setJoseph(josephDai.address);
    });

    it("should contain correct underlying token address", async () => {
        //given
        const { ipToken, tokenDai } = await preperateIpTokenCase010();
        const expectedUnderlyingTokenAddress = tokenDai.address;

        //when
        let actualUnderlyingTokenAddress = await ipToken.getAsset();

        //then
        expect(
            expectedUnderlyingTokenAddress,
            `Incorrect underlying token address actual: ${actualUnderlyingTokenAddress}, expected: ${expectedUnderlyingTokenAddress}`
        ).to.be.equal(actualUnderlyingTokenAddress);
    });

    it("should not sent ETH to IpToken DAI", async () => {
        //given
        const { ipToken } = await preperateIpTokenCase010();

        await assertError(
            //when
            admin.sendTransaction({
                to: ipToken.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });
});
