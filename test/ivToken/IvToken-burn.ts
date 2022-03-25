import hre from "hardhat";
import chai from "chai";
import { constants, Signer } from "ethers";
import { IvToken } from "../../types";
import { ZERO, N1__0_18DEC } from "../utils/Constants";

const { expect } = chai;

describe("#IvToken burn function tests", () => {
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

    it("should NOT burn IvToken if not a Stanley", async () => {
        //given
        await expect(
            //when
            ivToken.burn(await userOne.getAddress(), N1__0_18DEC)
            //then
        ).to.be.revertedWith("IPOR_501");
    });

    it("should not be able to burn when amount is 0", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        const amount = ZERO;

        await ivToken.setStanley(mockIporVaultAddress);
        await expect(
            //when
            ivToken.connect(userOne).burn(await userOne.getAddress(), amount)
            //then
        ).to.be.revertedWith("IPOR_504");
    });

    it("should not be able to burn when pass zero address", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        const amount = ZERO;

        await ivToken.setStanley(mockIporVaultAddress);
        await expect(
            //when
            ivToken.connect(userOne).burn(constants.AddressZero, N1__0_18DEC)
            //then
        ).to.be.revertedWith("ERC20: burn from the zero address");
    });

    it("should not be able to burn when burn amount exceeds balance", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        const amount = N1__0_18DEC;
        const addressOne = await userOne.getAddress();

        await ivToken.setStanley(mockIporVaultAddress);

        //when
        await expect(ivToken.connect(userOne).burn(addressOne, amount))
            //then
            .to.be.revertedWith("ERC20: burn amount exceeds balance");
    });

    it("should burn tokens", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        const amount = N1__0_18DEC;
        const addressOne = await userOne.getAddress();

        await ivToken.setStanley(mockIporVaultAddress);
        await ivToken.connect(userOne).mint(await userOne.getAddress(), amount);

        //when
        await expect(ivToken.connect(userOne).burn(addressOne, amount))
            //then
            .to.emit(ivToken, "Burn")
            .withArgs(addressOne, amount)
            .and.to.emit(ivToken, "Transfer")
            .withArgs(addressOne, constants.AddressZero, amount);
    });
});
