// @ts-ignore
const hre = require("hardhat");
import chai from "chai";
import { constants, Signer } from "ethers";
import { solidity } from "ethereum-waffle";
chai.use(solidity);
const { expect } = chai;

import { IporOwnableUpgradeable } from "../../../../types";

describe("IporOwnableUpgradeable", () => {
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let iporOwnable: IporOwnableUpgradeable;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        const IporOwnableUpgradeable = await hre.ethers.getContractFactory(
            "MockIporOwnableUpgradeable"
        );
        iporOwnable =
            (await IporOwnableUpgradeable.deploy()) as IporOwnableUpgradeable;
    });

    it("Should 0x00 address be owner when deployed without initialize", async () => {
        // given
        // when
        // then
        const owner = await iporOwnable.owner();
        expect(owner, "should be 0x00 address").to.be.equal(
            constants.AddressZero
        );
    });

    it("Should deployer be owner of contract", async () => {
        // given
        // @ts-ignore
        iporOwnable.initialize();
        // when
        // then
        const owner = await iporOwnable.owner();
        expect(owner, "Admin should be owner").to.be.equal(
            await admin.getAddress()
        );
    });

    it("Should not be posible to transfer 0x00 address", async () => {
        // given
        // @ts-ignore
        iporOwnable.initialize();
        // when
        await expect(
            iporOwnable.transferOwnership(constants.AddressZero),
            "Should revert when 0x00 addres pass"
        ).revertedWith("IPOR_37");
    });

    it("should not be possible to confirm the transfer ownership for different address", async () => {
        // given
        // @ts-ignore
        iporOwnable.initialize();
        await iporOwnable.transferOwnership(await userOne.getAddress());
        await expect(
            iporOwnable.connect(userTwo).confirmTransferOwnership(),
            "Should revert when pass userTwo address"
        ).revertedWith("IPOR_6");
    });

    it("Should be able to transfer ownership to userOne", async () => {
        // when
        // @ts-ignore
        iporOwnable.initialize();
        await iporOwnable.transferOwnership(await userOne.getAddress());
        await iporOwnable.connect(userOne).confirmTransferOwnership();
        // then
        const owner = await iporOwnable.owner();

        expect(owner, "userOne should be owner").to.be.equal(
            await userOne.getAddress()
        );
    });
});
