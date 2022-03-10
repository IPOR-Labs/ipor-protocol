const hre = require("hardhat");
import chai from "chai";
import { constants, Signer } from "ethers";
import { solidity } from "ethereum-waffle";
chai.use(solidity);
const { expect } = chai;

import { IporOwnable } from "../../../../types";

describe("IporOwnable", () => {
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let iporOwnable: IporOwnable;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        const IporOwnable = await hre.ethers.getContractFactory("IporOwnable");
        iporOwnable = await IporOwnable.deploy();
    });

    it("Should deployer be owner of contract", async () => {
        // given
        // when
        // then
        const owner = await iporOwnable.owner();
        expect(owner, "Admin should be owner").to.be.equal(await admin.getAddress());
    });

    it("Should not be posible to transfer 0x00 address", async () => {
        // given
        // when
        await expect(
            iporOwnable.transferOwnership(constants.AddressZero),
            "Should revert when 0x00 addres pass"
        ).revertedWith("IPOR_001");
    });

    it("should not be possible to confirm the transfer ownership for different address", async () => {
        // given
        await iporOwnable.transferOwnership(await userOne.getAddress());
        // when
        await expect(
            iporOwnable.connect(userTwo).confirmTransferOwnership(),
            "Should revert when pass userTwo address"
        ).revertedWith("IPOR_006");
    });

    it("Should be able to transfer ownership to userOne", async () => {
        // when
        await iporOwnable.transferOwnership(await userOne.getAddress());
        await iporOwnable.connect(userOne).confirmTransferOwnership();
        // then
        const owner = await iporOwnable.owner();

        expect(owner, "userOne should be owner").to.be.equal(await userOne.getAddress());
    });
});
