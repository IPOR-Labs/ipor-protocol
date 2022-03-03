const hre = require("hardhat");
import chai from "chai";
import { BigNumber } from "ethers";
import { solidity } from "ethereum-waffle";
chai.use(solidity);
const { expect } = chai;
import { MockExchangeRate } from "../../../../types";
const itParam = require("mocha-param");

type TestData = {
    totalAssetsDollar: BigNumber;
    totalTokensIssued: BigNumber;
    result: BigNumber;
};
const ZERO = BigNumber.from("0");
const ONED18 = BigNumber.from("1000000000000000000");

const data: TestData[] = [
    { totalAssetsDollar: ZERO, totalTokensIssued: ZERO, result: ONED18 },
    {
        totalAssetsDollar: BigNumber.from(1),
        totalTokensIssued: BigNumber.from(1),
        result: ONED18,
    },
    { totalAssetsDollar: ZERO, totalTokensIssued: ONED18, result: ONED18 },
    { totalAssetsDollar: ONED18, totalTokensIssued: ZERO, result: ONED18 },
    {
        totalAssetsDollar: ONED18,
        totalTokensIssued: ONED18.mul(2),
        result: BigNumber.from("500000000000000000"),
    },
    {
        totalAssetsDollar: ONED18,
        totalTokensIssued: BigNumber.from("500000000000000000"),
        result: ONED18.mul(2),
    },
    {
        totalAssetsDollar: ONED18,
        totalTokensIssued: BigNumber.from("1"),
        result: BigNumber.from("1000000000000000000000000000000000000"),
    },
    {
        totalAssetsDollar: BigNumber.from("1"),
        totalTokensIssued: ONED18.mul(2),
        result: BigNumber.from("1"),
    },
    {
        totalAssetsDollar: BigNumber.from("1"),
        totalTokensIssued: ONED18.mul(3),
        result: ZERO,
    },
];

describe("#ExchangeRate test", () => {
    let exchangeRate: MockExchangeRate;
    beforeEach(async () => {
        const ExchangeRate = await hre.ethers.getContractFactory(
            "MockExchangeRate"
        );
        exchangeRate = await ExchangeRate.deploy();
    });

    itParam(
        "should return ${value.result} when totalAssetsDollar: ${value.totalAssetsDollar} and totalTokensIssued: ${value.totalTokensIssued}",
        data,
        async (value: TestData) => {
            // given
            const { totalAssetsDollar, totalTokensIssued, result } = value;

            // when
            const exchangeRateResult = await exchangeRate.calculateExchangeRate(
                totalAssetsDollar,
                totalTokensIssued
            );
            // then
            expect(exchangeRateResult.toString()).to.be.equal(
                result.toString()
            );
        }
    );
});
