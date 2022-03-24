import hre from "hardhat";
import chai from "chai";
import { BigNumber } from "ethers";
import { MockIporSwapLogic } from "../../types";
import {
    ONE_18DEC,
    ONE_16DEC,
    YEAR_IN_SECONDS,
    SWAP_DEFAULT_PERIOD_IN_SECONDS,
} from "../utils/Constants";

const { expect } = chai;

describe("IporSwapLogic calculateQuasiInterestFixed", () => {
    let iporSwapLogic: MockIporSwapLogic;

    before(async () => {
        const MockIporSwapLogic = await hre.ethers.getContractFactory("MockIporSwapLogic");
        iporSwapLogic = (await MockIporSwapLogic.deploy()) as MockIporSwapLogic;
        iporSwapLogic.deployed();
    });

    it("Calculate Interest Fixed Case 1", async () => {
        //given
        const notionalAmount = BigNumber.from("98703").mul(ONE_18DEC);
        const swapFixedInterestRate = BigNumber.from("4").mul(ONE_16DEC);
        const swapPeriodInSeconds = 0;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
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
        const notionalAmount = BigNumber.from(98703).mul(ONE_18DEC);
        const swapFixedInterestRate = BigNumber.from("4").mul(ONE_16DEC);
        const swapPeriodInSeconds = SWAP_DEFAULT_PERIOD_IN_SECONDS;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
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
        const notionalAmount = BigNumber.from("98703").mul(ONE_18DEC);
        const swapFixedInterestRate = BigNumber.from(4).mul(ONE_16DEC);
        const swapPeriodInSeconds = YEAR_IN_SECONDS;

        //when
        const result = await iporSwapLogic.calculateQuasiInterestFixed(
            notionalAmount,
            swapFixedInterestRate,
            swapPeriodInSeconds
        );

        //then
        expect(result, "Wrong interest fixed").to.be.equal(
            "3237205720320000000000000000000000000000000000000"
        );
    });
});
