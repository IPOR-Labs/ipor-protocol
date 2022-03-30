import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { N0__01_18DEC, N1__0_18DEC, N0__1_18DEC, PERCENTAGE_100_18DEC } from "../utils/Constants";

import { MiltonDai } from "../../types";

const { expect } = chai;

describe("MiltonConfiguration", () => {
    let miltonConfiguration: MiltonDai;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        const MiltonConfiguration = await hre.ethers.getContractFactory("MiltonDai");
        miltonConfiguration = (await MiltonConfiguration.deploy()) as MiltonDai;
    });

    it("should setup init value for Max Swap Total Amount", async () => {
        //when
        const actualValue = await miltonConfiguration.getMaxSwapCollateralAmount();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("100000").mul(N1__0_18DEC));
    });

    it("should setup init value for Max Lp Utilization Percentage", async () => {
        //when
        const actualValue = await miltonConfiguration.getMaxLpUtilizationPercentage();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("8").mul(N0__1_18DEC));
    });

    it("should setup init value for Max Lp Utilization Per Leg Percentage", async () => {
        //when
        const actualValue = await miltonConfiguration.getMaxLpUtilizationPerLegPercentage();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("48").mul(N0__01_18DEC));
    });

    it("should setup init value for Income Fee Percentage", async () => {
        //when
        const actualValue = await miltonConfiguration.getIncomeFeePercentage();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("1").mul(N0__1_18DEC));
    });

    it("should setup init value for Opening Fee Percentage", async () => {
        //when
        const actualValue = await miltonConfiguration.getOpeningFeePercentage();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("1").mul(N0__01_18DEC));
    });
    it("should setup init value for Opening Fee Treasury Percentage", async () => {
        //when
        const actualValue = await miltonConfiguration.getOpeningFeeForTreasuryPercentage();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("0"));
    });

    it("should setup init value for IPOR Publication Fee Amount", async () => {
        //when
        const actualValue = await miltonConfiguration.getIporPublicationFeeAmount();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("10").mul(N1__0_18DEC));
    });
    it("should setup init value for Liquidation Deposit Amount", async () => {
        //when
        const actualValue = await miltonConfiguration.getLiquidationDepositAmount();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("20").mul(N1__0_18DEC));
    });
    it("should setup init value for Max Leveragey Value", async () => {
        //when
        const actualValue = await miltonConfiguration.getMaxLeverageValue();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("1000").mul(N1__0_18DEC));
    });

    it("should setup init value for Min Leveragey Value", async () => {
        //when
        const actualValue = await miltonConfiguration.getMinLeverageValue();
        //then
        expect(actualValue).to.be.eq(BigNumber.from("10").mul(N1__0_18DEC));
    });

    it("should init value for Opening Fee Treasury Percentage lower than 100%", async () => {
        //when
        const actualValue = await miltonConfiguration.getOpeningFeeForTreasuryPercentage();
        //then
        expect(actualValue.lte(PERCENTAGE_100_18DEC)).to.be.true;
    });

    it("should init value for Income Fee Percentage lower than 100%", async () => {
        //when
        const actualValue = await miltonConfiguration.getIncomeFeePercentage();
        //then
        expect(actualValue.lte(PERCENTAGE_100_18DEC)).to.be.true;
    });
});
