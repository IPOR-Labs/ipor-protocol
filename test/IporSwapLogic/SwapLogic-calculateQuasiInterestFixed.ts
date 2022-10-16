import hre from "hardhat";
import chai from "chai";
import { BigNumber } from "ethers";
import { MockIporSwapLogic } from "../../types";
import {
    N1__0_18DEC,
    N0__01_18DEC,
    YEAR_IN_SECONDS,
    SWAP_DEFAULT_PERIOD_IN_SECONDS,
} from "../utils/Constants";

const { expect } = chai;

describe("IporSwapLogic calculateQuasiInterestFixed", () => {
    let iporSwapLogic: MockIporSwapLogic;

    before(async () => {
        const MockIporSwapLogic = await hre.ethers.getContractFactory("MockIporSwapLogic");
        iporSwapLogic = (await MockIporSwapLogic.deploy()) as MockIporSwapLogic;
    });

    it("Calculate Interest Fixed Case 1", async () => {
        //given
        const notional = BigNumber.from("98703").mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swapPeriodInSeconds = 0;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notional,
            swapFixedInterestRate,
            swapPeriodInSeconds
        );

        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3112697808000000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Fixed Case 2", async () => {
        //given
        const notional = BigNumber.from(98703).mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swapPeriodInSeconds = SWAP_DEFAULT_PERIOD_IN_SECONDS;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notional,
            swapFixedInterestRate,
            swapPeriodInSeconds
        );

        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3122249099904000000000000000000000000000000000000"
        );
    });

    it("Calculate Interest Fixed Case 3", async () => {
        //given
        const notional = BigNumber.from("98703").mul(N1__0_18DEC);
        const swapFixedInterestRate = BigNumber.from(4).mul(N0__01_18DEC);
        const swapPeriodInSeconds = YEAR_IN_SECONDS;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notional,
            swapFixedInterestRate,
            swapPeriodInSeconds
        );

        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3237205720320000000000000000000000000000000000000"
        );
    });

});
