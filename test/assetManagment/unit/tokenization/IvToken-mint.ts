const hre = require("hardhat");
import chai from "chai";
import { constants, BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";
chai.use(solidity);
const { expect } = chai;

import { IvToken } from "../../../../types";

describe("#IvToken mint function tests", () => {
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

    it("should not to be able mint when sender is not IporVault", async () => {
        //given
        await expect(
            //when
            ivToken.mint(await userOne.getAddress(), BigNumber.from("10"))
            //then
        ).to.be.revertedWith("IPOR_ASSET_MANAGMENT_08");
    });

    it("should not be able to mint when amount is  0", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        await ivToken.setVault(mockIporVaultAddress);
        const amount = BigNumber.from("0");
        await expect(
            //when
            ivToken.connect(userOne).mint(await userOne.getAddress(), amount)
            //then
        ).to.be.revertedWith("IPOR_ASSET_MANAGMENT_02");
    });

    it("should not be able to mint when pass zero address", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        await ivToken.setVault(mockIporVaultAddress);
        const amount = BigNumber.from("0");
        await expect(
            //when
            ivToken
                .connect(userOne)
                .mint(constants.AddressZero, BigNumber.from(1))
            //then
        ).to.be.revertedWith("ERC20: mint to the zero address");
    });

    it("should mint new tokens", async () => {
        //given
        const mockIporVaultAddress = await userOne.getAddress();
        await ivToken.setVault(mockIporVaultAddress);
        const amount = BigNumber.from("10");
        const addressOne = await userOne.getAddress();

        //when
        await expect(ivToken.connect(userOne).mint(addressOne, amount))
            //then
            .to.emit(ivToken, "Mint")
            .withArgs(addressOne, amount)
            .and.to.emit(ivToken, "Transfer")
            .withArgs(constants.AddressZero, addressOne, amount);
    });
});
