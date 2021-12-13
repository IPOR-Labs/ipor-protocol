const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_18DEC = BigInt("1000000000000000000");

describe("TotalSoapIndicatorLogic", () => {
    let SoapIndicatorLogic;

    before(async () => {
        const TotalSoapIndicatorLogic = await ethers.getContractFactory(
            "TotalSoapIndicatorLogic"
        );
        const totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deploy();
        await totalSoapIndicatorLogic.deployed();

        MockTotalSoapIndicatorLogic = await ethers.getContractFactory(
            "MockTotalSoapIndicatorLogic"
        );
        mockTotalSoapIndicatorLogic =
            await MockTotalSoapIndicatorLogic.deploy();
        await mockTotalSoapIndicatorLogic.deployed();
    });
});
