import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { IvToken, DaiMockedToken } from "../../types";
import { TOTAL_SUPPLY_18_DECIMALS } from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";

const { expect } = chai;

describe("IvToken", () => {
    let admin: Signer, userOne: Signer, userTwo: Signer, userThree: Signer;
    let ivToken: IvToken;
    let ivTokenDai: IvToken;
    let tokenDai: DaiMockedToken;

    before(async () => {
        [admin, userOne, userTwo, userThree] = await hre.ethers.getSigners();
        const DaiMockedToken = await hre.ethers.getContractFactory("DaiMockedToken");
        tokenDai = (await DaiMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18)) as DaiMockedToken;
    });

    beforeEach(async () => {
        const tokenFactory = await hre.ethers.getContractFactory("IvToken");
        ivTokenDai = (await tokenFactory.deploy("IV DAI", "ivDAI", tokenDai.address)) as IvToken;

        ivToken = (await tokenFactory.deploy(
            "IvToken",
            "IVT",
            "0x6b175474e89094c44da98b954eedeac495271d0f"
        )) as IvToken;
        await ivToken.deployed();
    });

    it("Should not be able to setup vault address when is not owner", async () => {
        //when
        await expect(
            ivToken.connect(userOne).setStanley("0x6b175474e89094c44da98b954eedeac495271d0f"),
            "Only owner should be able to set vault address"
        ).revertedWith("Ownable: caller is not the owner");
    });

    it("should contain 18 decimals", async () => {
        //given
        await ivTokenDai.setStanley(await admin.getAddress());
        const expectedDecimals = BigNumber.from("18");
        //when
        const actualDecimals = await ivTokenDai.decimals();

        //then
        expect(
            expectedDecimals,
            `Incorrect decimals actual: ${actualDecimals}, expected: ${expectedDecimals}`
        ).to.be.equal(actualDecimals);
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await ivTokenDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await ivTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await ivTokenDai.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            ivTokenDai.connect(userThree).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await ivTokenDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await assertError(
            ivTokenDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await ivTokenDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await ivTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            ivTokenDai.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const expectedNewOwner = userTwo;

        await ivTokenDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await ivTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            ivTokenDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const expectedNewOwner = userTwo;

        await ivTokenDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //when
        await ivTokenDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await ivTokenDai.connect(userOne).owner();
        expect(await admin.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should contain 18 decimals", async () => {
        //given
        await ivTokenDai.setStanley(await admin.getAddress());
        const expectedDecimals = BigNumber.from("18");
        //when
        const actualDecimals = await ivTokenDai.decimals();

        //then
        expect(
            expectedDecimals,
            `Incorrect decimals actual: ${actualDecimals}, expected: ${expectedDecimals}`
        ).to.be.equal(actualDecimals);
    });

    it("should contain correct underlying token address", async () => {
        //given
        const expectedUnderlyingTokenAddress = tokenDai.address;
        //when
        const actualUnderlyingTokenAddress = await ivTokenDai.getAsset();

        //then
        expect(
            expectedUnderlyingTokenAddress,
            `Incorrect underlying token address actual: ${actualUnderlyingTokenAddress}, expected: ${expectedUnderlyingTokenAddress}`
        ).to.be.eql(actualUnderlyingTokenAddress);
    });

    it("should not sent ETH to IvToken DAI", async () => {
        //given

        await assertError(
            //when
            admin.sendTransaction({
                to: ivTokenDai.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });
});
