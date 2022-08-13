import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    N1__0_18DEC,
    N0__001_18DEC,
    N0__000_1_18DEC,
    N0__000_01_18DEC,
    N0__000_001_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_15_000_18DEC,
    USD_13_000_18DEC,
    USD_20_18DEC,
    ZERO,
    N0__01_18DEC,
} from "../utils/Constants";
import { prepareMockSpreadModel, prepareMiltonSpreadBaseDai } from "../utils/MiltonUtils";

const { expect } = chai;

describe("MiltonSpreadRecFixed", () => {
    let miltonSpreadModel: MockSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockSpreadModel(ZERO, ZERO, ZERO, ZERO);
    });

    it("[!] should calculate Quote Value Receive Fixed Value - Spread Premiums negative, |Spread Premium| < IPOR Index, EMA > Quote Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("1").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("1").mul(N0__000_01_18DEC),
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

        const expectedQuoteValue = BigNumber.from("6944924491911620");

        //when
        const actualQuotedValue = await miltonSpread
            .connect(userOne)
            .callStatic.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);

        //Actual EMA higher than Quote Value for this particular test case.
        expect(accruedIpor.exponentialMovingAverage).to.be.gte(actualQuotedValue);
    });

    it("[!] should calculate Quote Value Receive Fixed Value - Spread Premiums negative, |Spread Premium| > IPOR Index, normal EMVAr, quote < 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;

        const accruedIpor = {
            indexValue: BigNumber.from("9").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("1").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("1").mul(N0__000_001_18DEC),
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

        const expectedQuoteValue = BigNumber.from("0");

        //when
        const actualQuotedValue = await miltonSpread
            .connect(userOne)
            .callStatic.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);

        //Actual EMA cannot be lower than Quote Value for this particular test case.
        expect(accruedIpor.exponentialMovingAverage).to.be.gte(actualQuotedValue);
    });

    it("should calculate Quote Value Receive Fixed Value - Spread Premiums negative, | Spread Premium | > IPOR Index", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;

        const accruedIpor = {
            indexValue: BigNumber.from("4").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("3").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("1").mul(N0__001_18DEC),
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

        const expectedQuoteValue = BigNumber.from("0");

        //when
        const actualQuotedValue = await miltonSpread
            .connect(userOne)
            .callStatic.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });

    it("should calculate Quote Value Receive Fixed Value - Spread Premiums negative, | Spread Premium | < IPOR Index", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;

        const accruedIpor = {
            indexValue: BigNumber.from("4").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("3").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("1").mul(N0__000_001_18DEC),
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

        const expectedQuoteValue = BigNumber.from("28578745487231226");

        //when
        const actualQuotedValue = await miltonSpread
            .connect(userOne)
            .callStatic.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);

        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);

        //Actual Quote Value cannot be higher than 2xIndex Value for this particular test case.
        expect(accruedIpor.indexValue.mul(BigNumber.from(2))).to.be.gte(actualQuotedValue);
    });
});
