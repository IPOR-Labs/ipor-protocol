const { expect } = require("chai");
const { ethers } = require("hardhat");
const { YEARS_IN_SECONDS } = require("./Const.js");
const ONE_18DEC = BigInt("1000000000000000000");
const ONE_16DEC = BigInt("10000000000000000");

describe("SoapIndicatorLogic", () => {
    let mockSoapIndicatorLogic;

    before(async () => {
        const SoapIndicatorLogic = await ethers.getContractFactory(
            "SoapIndicatorLogic"
        );
        const soapIndicatorLogic = await SoapIndicatorLogic.deploy();
        await soapIndicatorLogic.deployed();

        const MockSoapIndicatorLogic = await ethers.getContractFactory(
            "MockSoapIndicatorLogic"
        );
        mockSoapIndicatorLogic = await MockSoapIndicatorLogic.deploy();
        await mockSoapIndicatorLogic.deployed();
    });

    it("should calculate interest rate when open position - simple case - 18 decimals", async () => {
        //given
        const soapIndicator = await prepareSoapIndicatorPfCaseD18();
        const derivativeNotional = BigInt(10000) * ONE_18DEC;
        const derivativeFixedInterestRate = BigInt(4) * ONE_16DEC;

        //when

        const actualInterestRate =
            await mockSoapIndicatorLogic.calculateInterestRateWhenOpenPosition(
                soapIndicator,
                derivativeNotional,
                derivativeFixedInterestRate
            );

        //then
        const expectedInterestRate = BigInt("66666666666666667");
        expect(
            expectedInterestRate,
            "Wrong interest rate when open position"
        ).to.be.eq(actualInterestRate);
    });

    const prepareSoapIndicatorPfCaseD18 = async () => {
        return {
            rebalanceTimestamp: Math.floor(Date.now() / 1000),
            direction: "0",
            quasiHypotheticalInterestCumulative:
                BigInt("500") *
                ONE_18DEC *
                ONE_18DEC *
                ONE_18DEC *
                YEARS_IN_SECONDS,

            totalNotional: BigInt("20000000000000000000000"),
            averageInterestRate: BigInt("80000000000000000"),
            totalIbtQuantity: BigInt("100000000000000000000"),
            soap: BigInt("0"),
        };
    };
});
