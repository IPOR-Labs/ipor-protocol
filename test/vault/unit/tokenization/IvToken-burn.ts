const hre = require("hardhat");
import chai from "chai";
import { constants, BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";
chai.use(solidity);
const { expect } = chai;
const keccak256 = require("keccak256");

import { IvToken } from "../../../../types";

describe("#IvToken burn function tests", () => {
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let ivToken: IvToken;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("IvToken");
        ivToken = await tokenFactory.deploy(
            "IvToken",
            "IVT",
            "0x6b175474e89094c44da98b954eedeac495271d0f"
        );
    });

    it("should not to be able burn when sender is not Stanley", async () => {
        //given
        await expect(
            //when
            ivToken.burn(await userOne.getAddress(), BigNumber.from("10"))
            //then
        ).to.be.revertedWith("IPOR_501");
    });

    it("should not be able to burn when amount is 0", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        await ivToken.setStanley(mockIporVaultAddress);
        const amount = BigNumber.from("0");
        await expect(
            //when
            ivToken.connect(userOne).burn(await userOne.getAddress(), amount)
            //then
        ).to.be.revertedWith("IPOR_504");
    });

    it("should not be able to burn when pass zero address", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        await ivToken.setStanley(mockIporVaultAddress);
        const amount = BigNumber.from("0");
        await expect(
            //when
            ivToken.connect(userOne).burn(constants.AddressZero, BigNumber.from(1))
            //then
        ).to.be.revertedWith("ERC20: burn from the zero address");
    });

    it("should not be able to burn when burn amount exceeds balance", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        await ivToken.setStanley(mockIporVaultAddress);
        const amount = BigNumber.from("10");
        const addressOne = await userOne.getAddress();

        //when
        await expect(ivToken.connect(userOne).burn(addressOne, amount))
            //then
            .to.be.revertedWith("ERC20: burn amount exceeds balance");
    });

    it("should burn tokens", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        await ivToken.setStanley(mockIporVaultAddress);
        const amount = BigNumber.from("10");
        const addressOne = await userOne.getAddress();
        ivToken.connect(userOne).mint(await userOne.getAddress(), amount);

        //when
        await expect(ivToken.connect(userOne).burn(addressOne, amount))
            //then
            .to.emit(ivToken, "Burn")
            .withArgs(addressOne, amount)
            .and.to.emit(ivToken, "Transfer")
            .withArgs(addressOne, constants.AddressZero, amount);
    });
});
