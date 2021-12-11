const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_18DEC = BigInt("1000000000000000000");

describe("IporAssetConfiguration", () => {
    // let ammMath = null;
    let ammMath;

    before(async () => {
        const AmmMath = await ethers.getContractFactory("AmmMath");
        const aM = await AmmMath.deploy();
        await aM.deployed();

        AmmMathTest = await ethers.getContractFactory("MockAmmMath");
        ammMath = await AmmMathTest.deploy();
        await ammMath.deployed();
    });

    it("Calculate IbtQuantity case 1", async () => {
        //given
        const notionalAmount = BigInt(98703) * ONE_18DEC;
        const ibtPrice = BigInt(100) * ONE_18DEC;

        //when
        const ibtQuantity = await ammMath.calculateIbtQuantity(
            notionalAmount,
            ibtPrice
        );
        //then
        expect(ibtQuantity, "Wrong IBT Quantity").to.be.equal(
            "987030000000000000000"
        );
    });

    it("Calculate Income Tax Case 1", async () => {
        //given
        const profit = BigInt(500) * ONE_18DEC;
        const percentage = (BigInt(6) * ONE_18DEC) / BigInt(100);

        //when
        const actualIncomeTaxValue = await ammMath.calculateIncomeTax(
            profit,
            percentage
        );

        //then
        expect(actualIncomeTaxValue, "Wrong Income Tax").to.be.equal(
            "30000000000000000000"
        );
    });

    it("Calculate Derivative Amount Casec1", async () => {
        //given
        const totalAmount = BigInt(10180) * ONE_18DEC;
        const collateralizationFactor = BigInt(50) * ONE_18DEC;
        const liquidationDepositAmount = BigInt(20) * ONE_18DEC;
        const iporPublicationFeeAmount = BigInt(10) * ONE_18DEC;
        const openingFeePercentage = BigInt(3) * BigInt(1e14);

        //when
        const result = await ammMath.calculateDerivativeAmount(
            totalAmount,
            collateralizationFactor,
            liquidationDepositAmount,
            iporPublicationFeeAmount,
            openingFeePercentage
        );

        //then
        expect(result.notional, "Wrong Notional").to.be.equal(
            "500000000000000000000000"
        );
        expect(result.openingFee, "Wrong Opening Fee Amount").to.be.equal(
            "150000000000000000000"
        );
        expect(result.deposit, "Wrong Collateral").to.be.equal(
            "10000000000000000000000"
        );
    });
});
