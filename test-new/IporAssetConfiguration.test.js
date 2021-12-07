const { expect } = require("chai");
const { ethers } = require("hardhat");
const keccak256 = require("keccak256");
const MINDELAY = BigInt("86400");

const { TOTAL_SUPPLY_18_DECIMALS } = require("./Const.js");

const {
    assertError
} = require("./Utils");

describe("IporAssetConfiguration", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;

    let tokenDai = null;
    let ipTokenDai = null;
    let iporAssetConfigurationDAI = null;
    let timelockController = null;

    before( async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();

        const DaiMockedToken = await ethers.getContractFactory(
            "DaiMockedToken"
        );
        tokenDai = await DaiMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18);
        await tokenDai.deployed();

        const IpToken = await ethers.getContractFactory("IpToken");
        ipTokenDai = await IpToken.deploy(tokenDai.address, "IP DAI", "ipDAI");
        await ipTokenDai.deployed();

        const MockTimelockController = await ethers.getContractFactory(
            "MockTimelockController"
        );
        
        timelockController = await MockTimelockController.deploy(
            MINDELAY,
            [userOne.address],
            [userTwo.address]
        );
        await timelockController.deployed();
    });

    beforeEach(async  () => {
        const IporAssetConfigurationDai = await ethers.getContractFactory(
            "IporAssetConfigurationDai"
        );
        iporAssetConfigurationDAI = await IporAssetConfigurationDai.deploy(
            tokenDai.address,
            ipTokenDai.address
        );
        iporAssetConfigurationDAI.deployed();
    });

    it("should set default openingFeeForTreasuryPercentage", async () => {
        //given
        const expectedOpeningFeeForTreasuryPercentage = BigInt("0");

        //when
        const actualOpeningFeeForTreasuryPercentage =
            await iporAssetConfigurationDAI.getOpeningFeeForTreasuryPercentage();

        //then
        expect(
            expectedOpeningFeeForTreasuryPercentage,
            `Incorrect openingFeeForTreasuryPercentage actual: ${actualOpeningFeeForTreasuryPercentage}, expected: ${expectedOpeningFeeForTreasuryPercentage}`
        ).to.be.eql(BigInt(actualOpeningFeeForTreasuryPercentage));
    });

    it("should set openingFeeForTreasuryPercentage", async () => {
        //given
        const expectedOpeningFeeForTreasuryPercentage = BigInt(
            "1000000000000000000"
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI.connect(userOne).setOpeningFeeForTreasuryPercentage(
            expectedOpeningFeeForTreasuryPercentage
        );
        const actualOpeningFeeForTreasuryPercentage =
            await iporAssetConfigurationDAI.getOpeningFeeForTreasuryPercentage();

        //then
        expect(
            expectedOpeningFeeForTreasuryPercentage,
            `Incorrect openingFeeForTreasuryPercentage actual: ${actualOpeningFeeForTreasuryPercentage}, expected: ${expectedOpeningFeeForTreasuryPercentage}`
        ).to.be.eql(BigInt(actualOpeningFeeForTreasuryPercentage));
    });

    it("should NOT set openingFeeForTreasuryPercentage", async () => {
        //given
        const openingFeeForTreasuryPercentage = BigInt("1010000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
            userOne.address
        );

        await assertError(
            //when
            iporAssetConfigurationDAI.connect(userOne).setOpeningFeeForTreasuryPercentage(
                openingFeeForTreasuryPercentage
            ),

            //then
            "IPOR_24"
        );
    });

    it("should NOT set openingFeeForTreasuryPercentage when user does not have OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE role", async () => {
        //given
        const openingFeeForTreasuryPercentage = BigInt("1010000000000000000");

        await assertError(
            //when
            iporAssetConfigurationDAI.connect(userOne).setOpeningFeeForTreasuryPercentage(
                openingFeeForTreasuryPercentage
            ),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x6d0de9008651a921e7ec84f14cdce94213af6041f456fcfc8c7e6fa897beab0f`
        );
    });

    it("should NOT set incomeTaxPercentage", async () => {
        //given
        const incomeTaxPercentage = BigInt("1000000000000000001");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            userOne.address
        );

        await assertError(
            //when
            iporAssetConfigurationDAI.connect(userOne).setIncomeTaxPercentage(
                incomeTaxPercentage
            ),
            //then
            "IPOR_24"
        );
    });

    it("should set incomeTaxPercentage - case 1", async () => {
        //given

        const incomeTaxPercentage = BigInt("150000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI.connect(userOne).setIncomeTaxPercentage(
            incomeTaxPercentage
        );

        //then
        const actualIncomeTaxPercentage =
            await iporAssetConfigurationDAI.getIncomeTaxPercentage();

        expect(
            incomeTaxPercentage,
            `Incorrect incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${incomeTaxPercentage}`
        ).to.be.eql(BigInt(actualIncomeTaxPercentage));
    });
});
