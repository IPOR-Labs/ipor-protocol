import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    ZERO,
    N0__001_18DEC,
    USD_20_18DEC,
    N0__01_18DEC,
    USD_13_000_18DEC,
    USD_15_000_18DEC,
    N1__0_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
} from "../utils/Constants";
import { prepareMiltonSpreadBaseDai } from "../utils/MiltonUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Pay Fixed", () => {
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
    });

    it("should calculate Quote Value Pay Fixed Value - Spread Premiums positive, Spread Premiums > IPOR Index", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;

        const accruedIpor = {
            indexValue: BigNumber.from("13").mul(N0__01_18DEC), //13%
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("1").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("15").mul(N0__001_18DEC),
        };

        const accruedBalance = {
            totalCollateralPayFixed: BigNumber.from("1000").mul(N1__0_18DEC).add(swapCollateral),
            totalCollateralReceiveFixed: USD_13_000_18DEC,
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: liquidityPoolBalance.add(openingFee),
            treasury: ZERO,
        };

        const expectedQuoteValue = BigNumber.from("3222138708849583098");

        //when
        const actualQuotedValue = await miltonSpread
            .connect(userOne)
            .callStatic.calculateQuotePayFixed(accruedIpor, accruedBalance);

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);

        //Actual Index Value cannot be higher than Quote Value for this particular test case.
        expect(accruedIpor.indexValue).to.be.lte(actualQuotedValue);
    });

    it("should calculate Quote Value Pay Fixed Value - Spread Premiums positive", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;

        const accruedIpor = {
            indexValue: BigNumber.from("2").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("1").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("15").mul(N0__001_18DEC),
        };

        const accruedBalance = {
            totalCollateralPayFixed: BigNumber.from("1000").mul(N1__0_18DEC).add(swapCollateral),
            totalCollateralReceiveFixed: USD_13_000_18DEC,
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: liquidityPoolBalance.add(openingFee),
            treasury: ZERO,
        };

        const expectedQuoteValue = BigNumber.from("3218095531900806724");

        //when
        const actualQuotedValue = await miltonSpread
            .connect(userOne)
            .callStatic.calculateQuotePayFixed(accruedIpor, accruedBalance);
        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });
});
