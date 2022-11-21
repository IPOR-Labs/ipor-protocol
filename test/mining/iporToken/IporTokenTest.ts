import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { IpToken, IporToken } from "../../../types";

import { assertError } from "../../utils/AssertUtils";
import { prepareTestDataForMining } from "../../utils/DataUtils";
import { N1__0_18DEC } from "../../utils/Constants";

const keccak256 = require("keccak256");
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
