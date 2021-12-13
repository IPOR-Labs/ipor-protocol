const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_18DEC = BigInt("1000000000000000000");

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
});
