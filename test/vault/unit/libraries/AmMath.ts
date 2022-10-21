const hre = require("hardhat");
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";
chai.use(solidity);
const { expect } = chai;
import { MockIporMath } from "../../../../types";
import { N1__0_18DEC } from "../../../utils/Constants";
const itParam = require("mocha-param");

type DivisionDataType = {};

type DataForDivision = {
    numerator: string;
    denominator: string;
    result: string;
};

describe("#AmMath division", () => {
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let amMath: MockIporMath;

    const dataForDivision: DataForDivision[] = [
        { numerator: "0", denominator: "1", result: "0" },
        { numerator: "100", denominator: "100", result: "1" },
        { numerator: "1", denominator: "3", result: "0" },
        { numerator: "100", denominator: "3", result: "33" },
        { numerator: "100", denominator: "2", result: "50" },
    ];

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();
        const AmMathMock = await hre.ethers.getContractFactory("MockIporMath");
        amMath = await AmMathMock.deploy();
    });

    it("should revert when denominator is 0", async () => {
        await expect(
            //when
            amMath.division(BigNumber.from("1"), BigNumber.from("0"))
            //then
        ).to.revertedWith("Division or modulo division by zero");
    });

    itParam(
        "should devide ${value.numerator} by ${value.denominator} with result ${value.result}",
        dataForDivision,
        async (value: DataForDivision) => {
            //given
            const { numerator, denominator, result } = value;
            //when
            const resultFromLib = await amMath.division(
                BigNumber.from(numerator),
                BigNumber.from(denominator)
            );
            //then
            expect(resultFromLib.toString()).to.be.equal(result);
        }
    );

    it("Should add extra zeros wken convert to asset decimals", async () => {
        // when
        const result = await amMath.convertWadToAssetDecimals(N1__0_18DEC, BigNumber.from("20"));
        // then
        expect(result).to.be.equal(N1__0_18DEC.mul(BigNumber.from("100")));
    });

    it("Should add extra zeros wken convert to asset decimals", async () => {
        // when
        const result = await amMath.convertToWad(N1__0_18DEC, BigNumber.from("20"));
        // then
        expect(result).to.be.equal(N1__0_18DEC.div(BigNumber.from("100")));
    });
});
