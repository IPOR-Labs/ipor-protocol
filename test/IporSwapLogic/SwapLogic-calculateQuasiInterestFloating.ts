import hre from "hardhat";
import chai from "chai";
import { BigNumber } from "ethers";
import { MockIporSwapLogic } from "../../types";
import { N1__0_18DEC, N0__01_18DEC, N1__0_6DEC } from "../utils/Constants";

const { expect } = chai;

describe("IporSwapLogic calculateQuasiInterestFloating", () => {
    let iporSwapLogic: MockIporSwapLogic;

    before(async () => {
        const MockIporSwapLogic = await hre.ethers.getContractFactory("MockIporSwapLogic");
        iporSwapLogic = (await MockIporSwapLogic.deploy()) as MockIporSwapLogic;
    });

    it("Calculate Interest Floating Case", async () => {
        //given
        const ibtQuantity = BigNumber.from("987030000000000000000");
        const ibtCurrentPrice = BigNumber.from("100").mul(N1__0_18DEC);

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        expect(result, "Wrong interest floating").to.be.equal(
            "3112697808000000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Floating Case 2", async () => {
        //given
        const ibtQuantity = BigNumber.from("987030000000000000000");
        const ibtCurrentPrice = BigNumber.from("150").mul(N1__0_18DEC);

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        expect(result, "Wrong interest floating").to.be.equal(
            "4669046712000000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Floating Case 3", async () => {
        //given
        const ibtQuantity = BigNumber.from("987030000");
        const ibtCurrentPrice = BigNumber.from("100").mul(N1__0_18DEC);

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );

        //then
        expect(result, "Wrong interest floating").to.be.equal(
            "3112697808000000000000000000000000000"
        );
    });

    it("Calculate Interest Floating Case 4", async () => {
        //given
        const ibtQuantity = BigNumber.from("987030000");
        const ibtCurrentPrice = BigNumber.from(150).mul(N1__0_6DEC);

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFloating(
            ibtQuantity,
            ibtCurrentPrice
        );
        //then
        expect(result, "Wrong interest floating").to.be.equal("4669046712000000000000000");
    });
});
