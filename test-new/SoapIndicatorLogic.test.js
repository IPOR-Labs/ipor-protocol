const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_18DEC = BigInt("1000000000000000000");
const ONE_16DEC = BigInt("10000000000000000");

describe("SoapIndicatorLogic", () => {
    let SoapIndicatorLogic;

    before(async () => {
        const SoapIndicatorLogic = await ethers.getContractFactory(
            "SoapIndicatorLogic"
        );
        const soapIndicatorLogic = await SoapIndicatorLogic.deploy();
        await soapIndicatorLogic.deployed();

        MockSoapIndicatorLogic = await ethers.getContractFactory(
            "MockSoapIndicatorLogic"
        );
        mockSoapIndicatorLogic = await MockSoapIndicatorLogic.deploy();
        await mockSoapIndicatorLogic.deployed();
    });

    // it("should calculate interest rate when open position - simple case - 18 decimals", async () => {
    //     //given
    //     const soapIndicator = prepareSoapIndicatorPfCaseD18();
    //     const derivativeNotional = BigInt(10000) * ONE_18DEC;
    //     const derivativeFixedInterestRate = BigInt(4) * ONE_16DEC;

    //     //when
    //     const actualInterestRate =
    //         soapIndicator.calculateInterestRateWhenOpenPosition(
    //             derivativeNotional,
    //             derivativeFixedInterestRate
    //         );

    //     //then
    //     const expectedInterestRate = BigInt(66666666666666667);
    //     Assert.equal(
    //         expectedInterestRate,
    //         actualInterestRate,
    //         "Wrong interest rate when open position"
    //     );
    // });
});
