import { getEnabledCategories } from "node:trace_events";

const hre = require("hardhat");
import chai from "chai";
import { Signer } from "ethers";
import { solidity } from "ethereum-waffle";
chai.use(solidity);
const { expect } = chai;
const keccak256 = require("keccak256");

import { IvToken } from "../../../../types";

const ADMIN_ROLE = keccak256("ADMIN_ROLE");
const USER_ROLE = keccak256("USER_ROLE");

describe("IvToken", () => {
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
        await ivToken.deployed();
    });

    it("Should not be able to setup vault address when is not owner", async () => {
        //when
        await expect(
            ivToken
                .connect(userOne)
                .setStanley("0x6b175474e89094c44da98b954eedeac495271d0f"),
            "Only owner should be able to set vault address"
        ).revertedWith("Ownable: caller is not the owner");
    });
    // TODO: check event
    // it("Should be able to set Vault address", async () => {
    //when

    // ivToken.setStanley("0X6B175474E89094C44DA98B954EEDEAC495271D0F");

    // .to.emit(ivToken, "Vault")
    // .withArgs(
    //   "await admin.getAddress()",
    //   "0X6B175474E89094C44DA98B954EEDEAC495271D0F"
    // );
    //then
    // });
});
