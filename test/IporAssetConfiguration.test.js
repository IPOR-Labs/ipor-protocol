const { expect } = require("chai");
const { ethers } = require("hardhat");
const keccak256 = require("keccak256");
const { ZERO_BYTES32 } = require("@openzeppelin/test-helpers/src/constants");
const { time } = require("@openzeppelin/test-helpers");

const {
    TOTAL_SUPPLY_18_DECIMALS,
    TC_MULTIPLICATOR_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    MINDELAY,
} = require("./Const.js");

const { assertError } = require("./Utils");

describe("IporAssetConfiguration", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;

    let tokenDai = null;
    let ipTokenDai = null;
    let iporAssetConfigurationDAI = null;
    let timelockController = null;
    const mockAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();

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

    beforeEach(async () => {
        const IporAssetConfigurationDai = await ethers.getContractFactory(
            "IporAssetConfigurationDai"
        );
        iporAssetConfigurationDAI = await IporAssetConfigurationDai.deploy(
            tokenDai.address,
            ipTokenDai.address
        );
        iporAssetConfigurationDAI.deployed();
    });

    //TODO: add tests which checks initial values for every param

    it("should set Milton ", async () => {
        //given
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_ROLE"),
            admin.address
        );

        //when
        await iporAssetConfigurationDAI.setMilton(mockAddress);

        //then
        const result = await iporAssetConfigurationDAI.getMilton();
        expect(mockAddress).to.be.eql(result);
    });

    it("should NOT set Milton  when user does not have MILTON__ROLE role", async () => {
        //given

        await assertError(
            //when
            iporAssetConfigurationDAI.setMilton(mockAddress),

            //then
            "account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x57a20741ae1ee76695a182cdfb995538919da5f1f6a92bca097f37a35c4be803"
        );
    });

    it("should set Milton Storage", async () => {
        //given
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_STORAGE_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_STORAGE_ROLE"),
            admin.address
        );

        //when
        await iporAssetConfigurationDAI.setMiltonStorage(mockAddress);

        //then
        const result = await iporAssetConfigurationDAI.getMiltonStorage();
        expect(mockAddress).to.be.eql(result);
    });

    it("should NOT set Milton storage when user does not have MILTON_STORAGE_ROLE role", async () => {
        //given

        await assertError(
            //when
            iporAssetConfigurationDAI.setMiltonStorage(mockAddress),

            //then
            "account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0xb8f71ab818f476672f61fd76955446cd0045ed8ddb51f595d9e262b68d1157f6"
        );
    });

    it("should set joseph", async () => {
        //given
        const adminRole = keccak256("JOSEPH_ADMIN_ROLE");
        await iporAssetConfigurationDAI.grantRole(adminRole, admin.address);
        const role = keccak256("JOSEPH_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, admin.address);

        //when
        await iporAssetConfigurationDAI.setJoseph(mockAddress);

        //then
        const result = await iporAssetConfigurationDAI.getJoseph();
        expect(mockAddress).to.be.eql(result);
    });

    it("should NOT set Joseph when user does not have JOSEPH_ROLE role", async () => {
        //given

        await assertError(
            //when
            iporAssetConfigurationDAI.setJoseph(mockAddress),

            //then
            `account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x2c03e103fc464998235bd7f80967993a1e6052d41cc085d3317ca8e301f51125`
        );
    });

    it("should use Timelock Controller - simple case 1", async () => {
        //given

        const fnParamAddress = userThree.address;
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_ROLE"),
            timelockController.address
        );

        const ABI = ["function setMilton(address milton) external"];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData("setMilton", [
            fnParamAddress,
        ]);

        //when
        await timelockController
            .connect(userOne)
            .schedule(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY
            );

        await time.increase(MINDELAY);

        await timelockController
            .connect(userTwo)
            .execute(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e"
            );

        //then
        const actualMiltonAddress = await iporAssetConfigurationDAI.getMilton();

        expect(
            fnParamAddress,
            `Incorrect Milton address actual: ${actualMiltonAddress}, expected: ${fnParamAddress}`
        ).to.be.eql(actualMiltonAddress);
    });

    it("should FAIL when used Timelock Controller, when  user not exists on list of proposers", async () => {
        //given
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_ROLE"),
            timelockController.address
        );
        const fnParamAddress = userThree.address;

        const ABI = ["function setMilton(address milton) external"];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData("setMilton", [
            fnParamAddress,
        ]);

        await assertError(
            //when
            timelockController
                .connect(userThree)
                .schedule(
                    iporAssetConfigurationDAI.address,
                    "0x0",
                    calldata,
                    ZERO_BYTES32,
                    "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                    MINDELAY
                ),

            //then
            "account 0x90f79bf6eb2c4f870365e785982e1f101e93b906 is missing role 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1"
        );
    });

    it("should FAIL when used Timelock Controller, because user not exists on list of executors", async () => {
        //given
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MILTON_ROLE"),
            timelockController.address
        );

        const fnParamAddress = userThree.address;

        const ABI = ["function setMilton(address milton) external"];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData("setMilton", [
            fnParamAddress,
        ]);

        await timelockController
            .connect(userOne)
            .schedule(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY
            );

        await time.increase(MINDELAY);

        await assertError(
            //when
            timelockController
                .connect(userThree)
                .execute(
                    iporAssetConfigurationDAI.address,
                    "0x0",
                    calldata,
                    ZERO_BYTES32,
                    "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e"
                ),

            //then
            "account 0x90f79bf6eb2c4f870365e785982e1f101e93b906 is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63"
        );
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
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setOpeningFeeForTreasuryPercentage(
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
            iporAssetConfigurationDAI
                .connect(userOne)
                .setOpeningFeeForTreasuryPercentage(
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
            iporAssetConfigurationDAI
                .connect(userOne)
                .setOpeningFeeForTreasuryPercentage(
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
            iporAssetConfigurationDAI
                .connect(userOne)
                .setIncomeTaxPercentage(incomeTaxPercentage),
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
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setIncomeTaxPercentage(incomeTaxPercentage);

        //then
        const actualIncomeTaxPercentage =
            await iporAssetConfigurationDAI.getIncomeTaxPercentage();

        expect(
            incomeTaxPercentage,
            `Incorrect incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${incomeTaxPercentage}`
        ).to.be.eql(BigInt(actualIncomeTaxPercentage));
    });

    it("should NOT set incomeTaxPercentage when user does not have INCOME_TAX_PERCENTAGE_ROLE role", async () => {
        //given
        const incomeTaxPercentage = BigInt("150000000000000000");

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setIncomeTaxPercentage(incomeTaxPercentage),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x1d60df71b356d37d065129ba494c44450d203a323cc11390563281105e480394`
        );
    });

    it("should set liquidationDepositAmount - case 1", async () => {
        //given
        const liquidationDepositAmount = BigInt("50000000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setLiquidationDepositAmount(liquidationDepositAmount);

        //then
        const actualLiquidationDepositAmount =
            await iporAssetConfigurationDAI.getLiquidationDepositAmount();
        expect(
            liquidationDepositAmount,
            `Incorrect liquidationDepositAmount actual: ${actualLiquidationDepositAmount}, expected: ${liquidationDepositAmount}`
        ).to.be.eql(BigInt(actualLiquidationDepositAmount));
    });

    it("should NOT set liquidationDepositAmount when user does not have LIQUIDATION_DEPOSIT_AMOUNT_ROLE role", async () => {
        //given
        const liquidationDepositAmount = BigInt("50000000000000000000");

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setLiquidationDepositAmount(liquidationDepositAmount),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xe5d97cc7ebc77e4491947e53b4b684cfaea4b3d5ec8734ba48d1fc4d2d54a42e`
        );
    });

    it("should NOT set openingFeePercentage", async () => {
        //given
        const openingFeePercentage = BigInt("1010000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
            userOne.address
        );

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setOpeningFeePercentage(openingFeePercentage),
            //then
            "IPOR_24"
        );
    });

    it("should set openingFeePercentage - case 1", async () => {
        //given
        const openingFeePercentage = BigInt("150000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setOpeningFeePercentage(openingFeePercentage);

        //then
        const actualOpeningFeePercentage =
            await iporAssetConfigurationDAI.getOpeningFeePercentage();
        expect(
            openingFeePercentage,
            `Incorrect openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${openingFeePercentage}`
        ).to.be.eql(BigInt(actualOpeningFeePercentage));
    });

    it("should NOT set openingFeePercentage when user does not have OPENING_FEE_PERCENTAGE_ROLE role", async () => {
        //given
        const openingFeePercentage = BigInt("150000000000000000");

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setOpeningFeePercentage(openingFeePercentage),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xe5f1f8ca5512a616c0bd4bc9709dc97b4fc337caf7a3c160e93904247bd8daab`
        );
    });

    it("should set iporPublicationFeeAmount - case 1", async () => {
        //given

        const iporPublicationFeeAmount = BigInt("999000000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setIporPublicationFeeAmount(iporPublicationFeeAmount);

        //then
        const actualIporPublicationFeeAmount =
            await iporAssetConfigurationDAI.getIporPublicationFeeAmount();
        expect(
            iporPublicationFeeAmount,
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`
        ).to.be.eql(BigInt(actualIporPublicationFeeAmount));
    });

    //TODO: clarify when spread equasion will be clarified
    // it("should set liquidityPoolMaxUtilizationPercentage higher than 100%", async () => {
    //     //given
    //     const liquidityPoolMaxUtilizationPercentage = BigInt(
    //         "99000000000000000000"
    //     );
    //     await iporAssetConfigurationDAI.grantRole(
    //         keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
    //         admin
    //     );
    //     await iporAssetConfigurationDAI.grantRole(
    //         keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
    //         userOne
    //     );

    //     //when
    //     await iporAssetConfigurationDAI.setLiquidityPoolMaxUtilizationPercentage(
    //         liquidityPoolMaxUtilizationPercentage,
    //         { from: userOne }
    //     );

    //     //then
    //     const actualLPMaxUtilizationPercentage =
    //         await iporAssetConfigurationDAI.getLiquidityPoolMaxUtilizationPercentage();
    //     assert(
    //         liquidityPoolMaxUtilizationPercentage ===
    //             BigInt(actualLPMaxUtilizationPercentage),
    //         `Incorrect LiquidityPoolMaxUtilizationPercentage actual: ${actualLPMaxUtilizationPercentage}, expected: ${liquidityPoolMaxUtilizationPercentage}`
    //     );
    // });

    it("should get initial liquidityPoolMaxUtilizationPercentage", async () => {
        //given
        const expectedLiquidityPoolMaxUtilizationPercentage =
            BigInt("800000000000000000");

        //when
        const actualLiquidityPoolMaxUtilizationPercentage =
            await iporAssetConfigurationDAI.getLiquidityPoolMaxUtilizationPercentage();

        //then
        expect(
            expectedLiquidityPoolMaxUtilizationPercentage,
            `Incorrect initial liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${expectedLiquidityPoolMaxUtilizationPercentage}`
        ).to.be.eql(BigInt(actualLiquidityPoolMaxUtilizationPercentage));
    });

    it("should set liquidityPoolMaxUtilizationPercentage", async () => {
        //given

        const liquidityPoolMaxUtilizationPercentage =
            BigInt("90000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setLiquidityPoolMaxUtilizationPercentage(
                liquidityPoolMaxUtilizationPercentage
            );

        //then
        const actualLiquidityPoolMaxUtilizationPercentage =
            await iporAssetConfigurationDAI.getLiquidityPoolMaxUtilizationPercentage();
        expect(
            liquidityPoolMaxUtilizationPercentage,
            `Incorrect liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${liquidityPoolMaxUtilizationPercentage}`
        ).to.be.eql(BigInt(actualLiquidityPoolMaxUtilizationPercentage));
    });

    it("should NOT set liquidityPoolMaxUtilizationPercentage when user does not have LP_MAX_UTILIZATION_PERCENTAGE_ROLE role", async () => {
        //given
        const liquidityPoolMaxUtilizationPercentage =
            BigInt("90000000000000000");

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setLiquidityPoolMaxUtilizationPercentage(
                    liquidityPoolMaxUtilizationPercentage
                ),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x1f68aca9d1b8ff5a2094c405f4385604851afa04a50632f403d9ae378700825e`
        );
    });

    it("should get initial incomeTaxPercentage", async () => {
        //given
        const expectedIncomeTaxPercentage = BigInt("100000000000000000");

        //when
        const actualIncomeTaxPercentage =
            await iporAssetConfigurationDAI.getIncomeTaxPercentage();

        //then
        expect(
            expectedIncomeTaxPercentage,
            `Incorrect initial incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${expectedIncomeTaxPercentage}`
        ).to.be.eql(BigInt(actualIncomeTaxPercentage));
    });

    it("should get initial liquidationDepositAmount", async () => {
        //given
        const expectedLiquidationDepositAmount = BigInt("20000000000000000000");

        //when
        const actualLiquidationDepositAmount =
            await iporAssetConfigurationDAI.getLiquidationDepositAmount();

        //then
        expect(
            expectedLiquidationDepositAmount,
            `Incorrect initial liquidationDepositAmount actual: ${actualLiquidationDepositAmount}, expected: ${expectedLiquidationDepositAmount}`
        ).to.be.eql(BigInt(actualLiquidationDepositAmount));
    });

    it("should get initial openingFeePercentage", async () => {
        //given
        let expectedOpeningFeePercentage = BigInt("300000000000000");

        //when
        const actualOpeningFeePercentage =
            await iporAssetConfigurationDAI.getOpeningFeePercentage();

        //then
        expect(
            expectedOpeningFeePercentage,
            `Incorrect initial openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${expectedOpeningFeePercentage}`
        ).to.be.eql(BigInt(actualOpeningFeePercentage));
    });

    it("should get initial iporPublicationFeeAmount", async () => {
        //given
        const expectedIporPublicationFeeAmount = BigInt("10000000000000000000");

        //when
        const actualIporPublicationFeeAmount =
            await iporAssetConfigurationDAI.getIporPublicationFeeAmount();

        //then
        expect(
            expectedIporPublicationFeeAmount,
            `Incorrect initial iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${expectedIporPublicationFeeAmount}`
        ).to.be.eql(BigInt(actualIporPublicationFeeAmount));
    });

    it("should get initial minCollateralizationFactorValue", async () => {
        //given
        const expectedMinCollateralizationFactorValue = BigInt(
            "10000000000000000000"
        );

        //when
        const actualMinCollateralizationFactorValue =
            await iporAssetConfigurationDAI.getMinCollateralizationFactorValue();

        //then
        expect(
            expectedMinCollateralizationFactorValue,
            `Incorrect initial MinCollateralizationFactorValue actual: ${actualMinCollateralizationFactorValue}, expected: ${expectedMinCollateralizationFactorValue}`
        ).to.be.eql(BigInt(actualMinCollateralizationFactorValue));
    });

    it("should get initial maxCollateralizationFactorValue", async () => {
        //given
        const expectedMaxCollateralizationFactorValue = BigInt(
            "1000000000000000000000"
        );

        //when
        const actualMaxCollateralizationFactorValue =
            await iporAssetConfigurationDAI.getMaxCollateralizationFactorValue();

        //then
        expect(
            expectedMaxCollateralizationFactorValue,
            `Incorrect initial MaxCollateralizationFactorValue actual: ${actualMaxCollateralizationFactorValue}, expected: ${expectedMaxCollateralizationFactorValue}`
        ).to.be.eql(BigInt(actualMaxCollateralizationFactorValue));
    });

    it("should use Timelock Controller - simple case 1", async () => {
        //given
        const iporPublicationFeeAmount = BigInt("999000000000000000000");

        const ABI = [
            "function setIporPublicationFeeAmount(uint256 iporPublicationFeeAmount) external",
        ];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData(
            "setIporPublicationFeeAmount",
            [iporPublicationFeeAmount]
        );

        await iporAssetConfigurationDAI.grantRole(
            keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"),
            timelockController.address
        );

        //when
        await timelockController
            .connect(userOne)
            .schedule(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY
            );

        await time.increase(MINDELAY);

        await timelockController
            .connect(userTwo)
            .execute(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e"
            );

        //then
        const actualIporPublicationFeeAmount =
            await iporAssetConfigurationDAI.getIporPublicationFeeAmount();
        expect(
            iporPublicationFeeAmount,
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`
        ).to.be.eql(BigInt(actualIporPublicationFeeAmount));
    });

    // TODO: chcek this
    it("should FAIL when used Timelock Controller, when user not exists on list of proposers", async () => {
        //given
        const iporPublicationFeeAmount = BigInt("999000000000000000000");
        const ABI = [
            "function setIporPublicationFeeAmount(uint256 iporPublicationFeeAmount) external",
        ];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData(
            "setIporPublicationFeeAmount",
            [iporPublicationFeeAmount]
        );

        await assertError(
            //when
            timelockController
                .connect(userThree)
                .schedule(
                    iporAssetConfigurationDAI.address,
                    "0x0",
                    calldata,
                    ZERO_BYTES32,
                    "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                    MINDELAY
                ),
            //then
            "account 0x90f79bf6eb2c4f870365e785982e1f101e93b906 is missing role 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1"
        );
    });

    it("should FAIL when used Timelock Controller, when user not exists on list of executors", async () => {
        //given
        const iporPublicationFeeAmount = BigInt("999000000000000000000");

        const ABI = [
            "function setIporPublicationFeeAmount(uint256 iporPublicationFeeAmount) external",
        ];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData(
            "setIporPublicationFeeAmount",
            [iporPublicationFeeAmount]
        );

        await timelockController
            .connect(userOne)
            .schedule(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY
            );

        await time.increase(MINDELAY);

        //when
        await assertError(
            //when
            timelockController
                .connect(userThree)
                .execute(
                    iporAssetConfigurationDAI.address,
                    "0x0",
                    calldata,
                    ZERO_BYTES32,
                    "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e"
                ),
            //then
            "account 0x90f79bf6eb2c4f870365e785982e1f101e93b906 is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63"
        );
    });

    it("should FAIL when used Timelock Controller, when Timelock is not an Owner of IporAssetConfiguration smart contract", async () => {
        //given
        const iporPublicationFeeAmount = BigInt("999000000000000000000");
        const ABI = [
            "function setIporPublicationFeeAmount(uint256 iporPublicationFeeAmount) external",
        ];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData(
            "setIporPublicationFeeAmount",
            [iporPublicationFeeAmount]
        );

        await timelockController
            .connect(userOne)
            .schedule(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY
            );

        await time.increase(MINDELAY);

        await assertError(
            //when
            timelockController
                .connect(userTwo)
                .execute(
                    iporAssetConfigurationDAI.address,
                    "0x0",
                    calldata,
                    ZERO_BYTES32,
                    "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e"
                ),
            //then
            "TimelockController: underlying transaction reverted"
        );
    });

    it("should use Timelock Controller to revoke ADMIN_ROLE role from admin", async () => {
        //given
        const iporAssetConfigurationOriginOwner = admin;
        const ADMIN_ROLE = keccak256("ADMIN_ROLE");
        await iporAssetConfigurationDAI.grantRole(
            ADMIN_ROLE,
            timelockController.address
        );

        const ABI = [
            "function revokeRole(bytes32 role, address account) public",
        ];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData("revokeRole", [
            ADMIN_ROLE,
            iporAssetConfigurationOriginOwner.address,
        ]);

        expect(
            await iporAssetConfigurationDAI.hasRole(
                ADMIN_ROLE,
                iporAssetConfigurationOriginOwner.address
            )
        ).to.be.true;
        expect(
            await iporAssetConfigurationDAI.hasRole(
                ADMIN_ROLE,
                timelockController.address
            )
        ).to.be.true;

        //when
        await timelockController
            .connect(userOne)
            .schedule(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY
            );

        await time.increase(MINDELAY);

        await timelockController
            .connect(userTwo)
            .execute(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e"
            );
        const hasRoleAdmin = await iporAssetConfigurationDAI.hasRole(
            ADMIN_ROLE,
            admin.address
        );
        expect(hasRoleAdmin).to.be.false;
    });

    it("should use Timelock Controller to grant ADMIN_ROLE role to userOne", async () => {
        //given
        const ADMIN_ROLE = keccak256("ADMIN_ROLE");
        await iporAssetConfigurationDAI.grantRole(
            ADMIN_ROLE,
            timelockController.address
        );

        const ABI = [
            "function grantRole(bytes32 role, address account) public",
        ];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData("grantRole", [
            ADMIN_ROLE,
            userOne.address,
        ]);

        expect(
            await iporAssetConfigurationDAI.hasRole(
                ADMIN_ROLE,
                timelockController.address
            )
        ).to.be.true;

        //when
        await timelockController
            .connect(userOne)
            .schedule(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY
            );

        await time.increase(MINDELAY);

        await timelockController
            .connect(userTwo)
            .execute(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e"
            );
        const hasRoleAdmin = await iporAssetConfigurationDAI.hasRole(
            ADMIN_ROLE,
            userOne.address
        );
        expect(hasRoleAdmin).to.be.true;
    });

    it("should set charlieTreasurer", async () => {
        //given
        const charlieTreasurersDaiAddress =
            "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenDai.address;
        await iporAssetConfigurationDAI.grantRole(
            keccak256("CHARLIE_TREASURER_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("CHARLIE_TREASURER_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setCharlieTreasurer(charlieTreasurersDaiAddress);

        //then
        const actualCharlieTreasurerDaiAddress =
            await iporAssetConfigurationDAI.getCharlieTreasurer();
        expect(
            charlieTreasurersDaiAddress,
            `Incorrect  Charlie Treasurer address for asset ${asset}, actual: ${actualCharlieTreasurerDaiAddress}, expected: ${charlieTreasurersDaiAddress}`
        ).to.be.eql(actualCharlieTreasurerDaiAddress);
    });

    it("should NOT set CharlieTreasurer when user does not have CHARLIE_TREASURER_ROLE role", async () => {
        //given
        const charlieTreasurersDaiAddress =
            "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setCharlieTreasurer(charlieTreasurersDaiAddress),
            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x21b203ce7b3398e0ad35c938bc2c62a805ef17dc57de85e9d29052eac6d9d6f7`
        );
    });

    it("should set treasureTreasurers", async () => {
        //given
        const treasureTreasurerDaiAddress =
            "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenDai.address;
        await iporAssetConfigurationDAI.grantRole(
            keccak256("TREASURE_TREASURER_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("TREASURE_TREASURER_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setTreasureTreasurer(treasureTreasurerDaiAddress);

        //then
        const actualTreasureTreasurerDaiAddress =
            await iporAssetConfigurationDAI.getTreasureTreasurer();

        expect(
            treasureTreasurerDaiAddress,
            `Incorrect  Trasure Treasurer address for asset ${asset}, actual: ${actualTreasureTreasurerDaiAddress}, expected: ${treasureTreasurerDaiAddress}`
        ).to.be.eql(actualTreasureTreasurerDaiAddress);
    });

    it("should NOT set TreasureTreasurer when user does not have TREASURE_TREASURER_ROLE role", async () => {
        //given
        const treasureTreasurerDaiAddress =
            "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setTreasureTreasurer(treasureTreasurerDaiAddress),
            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x9cdee4e06275597b667c73a5eb52ed89fe6acbbd36bd9fa38146b1316abfbbc4`
        );
    });

    it("should set asset management vault", async () => {
        //given
        const address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenDai.address;
        await iporAssetConfigurationDAI.grantRole(
            keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE"),
            admin.address
        );
        await iporAssetConfigurationDAI.grantRole(
            keccak256("ASSET_MANAGEMENT_VAULT_ROLE"),
            userOne.address
        );

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setAssetManagementVault(address);

        //then
        const actualAddress =
            await iporAssetConfigurationDAI.getAssetManagementVault();

        expect(
            address,
            `Incorrect  Asset Management Vault address for asset ${asset}, actual: ${actualAddress}, expected: ${address}`
        ).to.be.eql(actualAddress);
    });

    it("should NOT set AssetManagementVault when user does not have ASSET_MANAGEMENT_VAULT_ROLE role", async () => {
        //given
        const address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setAssetManagementVault(address),
            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x2a7b2b7d358f8b11f783d1505af660b492b725a034776176adc7c268915d5bd8`
        );
    });

    it("should set MaxPositionTotalAmount", async () => {
        //given
        const max = BigInt("999000000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne.address);

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setMaxSwapTotalAmount(max);

        //then
        const result = await iporAssetConfigurationDAI.getMaxSwapTotalAmount();
        expect(max).to.be.eql(BigInt(result));
    });

    it("should NOT set MaxPositionTotalAmount when user does not have MAX_POSITION_TOTAL_AMOUNT_ROLE role", async () => {
        //given
        const max = BigInt("999000000000000000000");

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setMaxSwapTotalAmount(max),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xbd6e7260790b38b2aece87cbeb2f1d97be9c3b1eb157efb80e7b3c341450caf2`
        );
    });

    it("should set MaxCollateralizationFactorValue", async () => {
        //given
        const max = BigInt("999000000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne.address);

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setMaxCollateralizationFactorValue(max);

        //then
        const result =
            await iporAssetConfigurationDAI.getMaxCollateralizationFactorValue();
        expect(max).to.be.eql(BigInt(result));
    });

    it("should NOT set MaxCollateralizationFactorValue when user does not have COLLATERALIZATION_FACTOR_VALUE_ROLE role", async () => {
        //given
        const max = BigInt("999000000000000000000");

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setMaxCollateralizationFactorValue(max),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xfa417488328f0d166e914b1aa9f0550c0823bf7e3a9e49d553e1ca6d505cc39e`
        );
    });

    it("should set MinCollateralizationFactorValue", async () => {
        //given
        const max = BigInt("999000000000000000000");
        await iporAssetConfigurationDAI.grantRole(
            keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne.address);

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setMinCollateralizationFactorValue(max);

        //then
        const result =
            await iporAssetConfigurationDAI.getMinCollateralizationFactorValue();
        expect(max).to.be.eql(BigInt(result));
    });

    it("should NOT set MinCollateralizationFactorValue when user does not have COLLATERALIZATION_FACTOR_VALUE_ROLE role", async () => {
        //given
        const max = BigInt("999000000000000000000");

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setMinCollateralizationFactorValue(max),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xfa417488328f0d166e914b1aa9f0550c0823bf7e3a9e49d553e1ca6d505cc39e`
        );
    });

    it("should set decay factor value", async () => {
        //given
        const decayFactorValue = TC_MULTIPLICATOR_18DEC;
        await iporAssetConfigurationDAI.grantRole(
            keccak256("DECAY_FACTOR_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("DECAY_FACTOR_VALUE_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne.address);

        //when
        await iporAssetConfigurationDAI
            .connect(userOne)
            .setDecayFactorValue(decayFactorValue);

        //then
        const actualDecayFactorValue = BigInt(
            await iporAssetConfigurationDAI.getDecayFactorValue()
        );

        expect(
            decayFactorValue,
            `Incorrect  decay factor value for asset DAI, actual: ${actualDecayFactorValue}, expected: ${decayFactorValue}`
        ).to.be.eql(actualDecayFactorValue);
    });

    it("should NOT set DecayFactorValue when user does not have DECAY_FACTOR_VALUE_ROLE role", async () => {
        //given
        const decayFactorValue = TC_MULTIPLICATOR_18DEC;

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setDecayFactorValue(decayFactorValue),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x94c58a89ab11d8b2894ecfbd6cb5c324f772536d0ea878a10cee7effe8ce98d0`
        );
    });

    it("should NOT set decay factor value, decay factor too high", async () => {
        //given
        const decayFactorValue = TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC;
        await iporAssetConfigurationDAI.grantRole(
            keccak256("DECAY_FACTOR_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("DECAY_FACTOR_VALUE_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne.address);

        await assertError(
            //when
            iporAssetConfigurationDAI
                .connect(userOne)
                .setDecayFactorValue(decayFactorValue),
            //then
            "IPOR_48"
        );
    });
});
