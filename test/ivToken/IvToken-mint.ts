import hre from "hardhat";
import chai from "chai";
import { constants, BigNumber, Signer } from "ethers";
import { IvToken } from "../../types";
import { ZERO, N1__0_18DEC, TC_TOTAL_AMOUNT_10_000_18DEC } from "../utils/Constants";

const { expect } = chai;

describe("#IvToken mint function tests", () => {
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let ivToken: IvToken;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("IvToken");
        ivToken = (await tokenFactory.deploy(
            "IvToken",
            "IVT",
            "0x6b175474e89094c44da98b954eedeac495271d0f"
        )) as IvToken;
    });

    it("should NOT mint IvToken if not a Stanley", async () => {
        //given
        await expect(
            //when
            ivToken.mint(await userOne.getAddress(), N1__0_18DEC)
            //then
        ).to.be.revertedWith("IPOR_501");
    });

    it("should not be able to mint when amount is  0", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        const amount = ZERO;

        await ivToken.setStanley(mockIporVaultAddress);
        await expect(
            //when
            ivToken.connect(userOne).mint(await userOne.getAddress(), amount)
            //then
        ).to.be.revertedWith("IPOR_503");
    });

    it("should not be able to mint when pass zero address", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();

        await ivToken.setStanley(mockIporVaultAddress);
        await expect(
            //when
            ivToken.connect(userOne).mint(constants.AddressZero, N1__0_18DEC)
            //then
        ).to.be.revertedWith("ERC20: mint to the zero address");
    });

    it("should mint new tokens", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        const amount = N1__0_18DEC;
        const addressOne = await userOne.getAddress();

        await ivToken.setStanley(mockIporVaultAddress);

        //when
        await expect(ivToken.connect(userOne).mint(addressOne, amount))
            //then
            .to.emit(ivToken, "Mint")
            .withArgs(addressOne, amount)
            .and.to.emit(ivToken, "Transfer")
            .withArgs(constants.AddressZero, addressOne, amount);
    });

    it("should emit event", async () => {
        //given
        await ivToken.setStanley(await admin.getAddress());

        await expect(ivToken.mint(await userOne.getAddress(), TC_TOTAL_AMOUNT_10_000_18DEC))
            .to.emit(ivToken, "Mint")
            .withArgs(await userOne.getAddress(), TC_TOTAL_AMOUNT_10_000_18DEC);
    });
});
