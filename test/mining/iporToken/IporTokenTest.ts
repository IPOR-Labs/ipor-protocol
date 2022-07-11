import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { IpToken, IporToken } from "../../../types";

import { assertError } from "../../utils/AssertUtils";
import { prepareTestDataForMining } from "../../utils/DataUtils";
import { N1__0_18DEC } from "../../utils/Constants";

const { expect } = chai;

describe("IporToken", () => {
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
    });

    after(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
    });

    const preperateTestDataCase01 = async (): Promise<{
        ipToken: IpToken;
        iporToken: IporToken;
    }> => {
        const testData = await prepareTestDataForMining(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"]
        );

        const { ipTokenDai, iporToken } = testData;

        if (ipTokenDai === undefined || iporToken === undefined) {
            throw new Error("Setup Error");
        } else {
            return { ipToken: ipTokenDai, iporToken };
        }
    };

    it("should transfer ownership - simple case 1", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { iporToken } = await preperateTestDataCase01();

        //when
        await iporToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());
        await iporToken.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await iporToken.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { iporToken } = await preperateTestDataCase01();

        //when
        await assertError(
            iporToken.connect(userThree).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { iporToken } = await preperateTestDataCase01();

        //when
        await iporToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());
        await assertError(
            iporToken.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { iporToken } = await preperateTestDataCase01();

        //when
        await iporToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());
        await iporToken.connect(expectedNewOwner).confirmTransferOwnership();
        await assertError(
            iporToken.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { iporToken } = await preperateTestDataCase01();

        await iporToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());
        await iporToken.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            iporToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const expectedNewOwner = userTwo;
        const { iporToken } = await preperateTestDataCase01();

        await iporToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //when
        await iporToken.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await iporToken.connect(userOne).owner();

        expect(await admin.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should contain 18 decimals", async () => {
        //given
        const { iporToken } = await preperateTestDataCase01();
        const expectedDecimals = BigNumber.from("18");

        //when
        const actualDecimals = await iporToken.decimals();

        //then
        expect(
            expectedDecimals,
            `Incorrect decimals actual: ${actualDecimals}, expected: ${expectedDecimals}`
        ).to.be.equal(actualDecimals);
    });

    it("should not sent ETH to IporToken", async () => {
        //given
        const { iporToken } = await preperateTestDataCase01();

        await assertError(
            //when
            admin.sendTransaction({
                to: iporToken.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });

    it("should contain initially 1 000 000 tokens in 18 decimals", async () => {
        //given
        const { iporToken } = await preperateTestDataCase01();
        const expectedTotalSupply = BigNumber.from("100000000").mul(N1__0_18DEC);

        //when
        const actualTotalSupply = await iporToken.totalSupply();

        //then
        expect(
            expectedTotalSupply,
            `Incorrect total supply actual: ${actualTotalSupply}, expected: ${expectedTotalSupply}`
        ).to.be.equal(actualTotalSupply);
    });

    it("should deployer contain initially 1 000 000 tokens in 18 decimals which is equal total supply", async () => {
        //given
        const { iporToken } = await preperateTestDataCase01();
        const expectedDeployerBalance = BigNumber.from("100000000").mul(N1__0_18DEC);

        //when
        const actualDeployerBalance = await iporToken.balanceOf(await admin.getAddress());
        const actualTotalSupply = await iporToken.totalSupply();

        //then
        expect(
            expectedDeployerBalance,
            `Incorrect deployer balance actual: ${actualDeployerBalance}, expected: ${expectedDeployerBalance}`
        ).to.be.equal(actualDeployerBalance);

        expect(
            expectedDeployerBalance,
            `Deployer balance is different than total supply, but should be the same.`
        ).to.be.equal(actualTotalSupply);
    });
});
