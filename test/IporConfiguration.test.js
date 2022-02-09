const { expect } = require("chai");
const { ethers } = require("hardhat");
const keccak256 = require("keccak256");
const { ZERO_BYTES32 } = require("@openzeppelin/test-helpers/src/constants");
const { time } = require("@openzeppelin/test-helpers");

const {
    TOTAL_SUPPLY_6_DECIMALS,
    TOTAL_SUPPLY_18_DECIMALS,
    MINDELAY,
} = require("./Const.js");

const { assertError } = require("./Utils");

describe("IporAssetConfiguration", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;

    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporConfiguration = null;
    let timelockController = null;
    const mockAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        const UsdtMockedToken = await ethers.getContractFactory(
            "UsdtMockedToken"
        );
        tokenUsdt = await UsdtMockedToken.deploy(TOTAL_SUPPLY_6_DECIMALS, 6);
        await tokenUsdt.deployed();

        const UsdcMockedToken = await ethers.getContractFactory(
            "UsdcMockedToken"
        );
        tokenUsdc = await UsdcMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18);
        await tokenUsdc.deployed();

        const DaiMockedToken = await ethers.getContractFactory(
            "DaiMockedToken"
        );
        tokenDai = await DaiMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18);
        await tokenDai.deployed();
    });

    beforeEach(async () => {
        const IporConfiguration = await ethers.getContractFactory(
            "IporConfiguration"
        );
        iporConfiguration = await IporConfiguration.deploy();
        await iporConfiguration.deployed();
		await iporConfiguration.initialize();

        await iporConfiguration.grantRole(
            keccak256("IPOR_ASSETS_ADMIN_ROLE"),
            admin.address
        );
        await iporConfiguration.grantRole(
            keccak256("IPOR_ASSETS_ROLE"),
            admin.address
        );
        await iporConfiguration.addAsset(tokenUsdt.address);
        await iporConfiguration.addAsset(tokenDai.address);

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

    it("should set IporAssetConfiguration for supported asset", async () => {
        //given
        const iporAssetConfigurationAddress =
            "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenDai.address;
        await iporConfiguration.grantRole(
            keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
            admin.address
        );
        await iporConfiguration.grantRole(
            keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
            admin.address
        );
        //when
        await iporConfiguration.setIporAssetConfiguration(asset, mockAddress);

        //then
        const actualIporAssetConfigurationAddress =
            await iporConfiguration.getIporAssetConfiguration(asset);
        expect(
            iporAssetConfigurationAddress,
            `Incorrect  IporAssetConfiguration address for asset ${asset}, actual: ${actualIporAssetConfigurationAddress}, expected: ${iporAssetConfigurationAddress}`
        ).to.be.eql(actualIporAssetConfigurationAddress);
    });

    it("should NOT set IporAssetConfiguration for NOT supported asset USDC", async () => {
        //given
        const iporAssetConfigurationAddress =
            "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenUsdc.address;

        await iporConfiguration.grantRole(
            keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
            admin.address
        );
        await iporConfiguration.grantRole(
            keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
            admin.address
        );
        //when
        await assertError(
            //when
            iporConfiguration.setIporAssetConfiguration(
                asset,
                iporAssetConfigurationAddress
            ),

            //then
            "IPOR_39"
        );
    });

    it("should NOT be able to add new asset when user does not have IPOR_ASSET_CONFIGURATION_ROLE role", async () => {
        //given
        const iporAssetConfigurationAddress =
            "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenUsdc.address;

        await assertError(
            //when
            iporConfiguration
                .connect(userOne)
                .setIporAssetConfiguration(
                    asset,
                    iporAssetConfigurationAddress
                ),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xe8f735d503f091d7e700cae87352987ca83ec17c9b2fb176dc5a5a7ec0390360`
        );
    });

   it("should set Milton Spread Strategy", async () => {
        //given
        const role = keccak256("MILTON_SPREAD_MODEL_ROLE");
        const adminRole = keccak256("MILTON_SPREAD_MODEL_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin.address);
        await iporConfiguration.grantRole(role, admin.address);

        //when
        await iporConfiguration.setMiltonSpreadModel(mockAddress);

        //then
        const result = await iporConfiguration.getMiltonSpreadModel();
        expect(mockAddress).to.be.eql(result);
    });

    it("should NOT set Milton Spread Strategy when user does not have MILTON_SPREAD_MODEL_ROLE role", async () => {
        //given

        await assertError(
            //when
            iporConfiguration.setMiltonSpreadModel(mockAddress),

            //then
            `account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0xc769312598bcfa61b1f22ed091835eefa5a0d9a37ea7646f63bfd88a3dd04878`
        );
    });

    it("should set Warren", async () => {
        //given
        const adminRole = keccak256("WARREN_ADMIN_ROLE");
        const role = keccak256("WARREN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin.address);
        await iporConfiguration.grantRole(role, admin.address);

        //when
        await iporConfiguration.setWarren(mockAddress);

        //then
        const result = await iporConfiguration.getWarren();
        expect(mockAddress).to.be.eql(result);
    });

    it("should NOT set Warren because user does not have WARREN_ROLE role", async () => {
        //given

        await assertError(
            //when
            iporConfiguration.setWarren(mockAddress),

            //then
            `account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0xe2062703bb72555ff94bfdd96351e7f292b8034f5f9127a25167d8d44f91ae85`
        );
    });

    it("should add new asset", async () => {
        //given
        const adminRole = keccak256("IPOR_ASSETS_ADMIN_ROLE");
        const role = keccak256("IPOR_ASSETS_ROLE");
        await iporConfiguration.grantRole(adminRole, userOne.address);
        await iporConfiguration.grantRole(role, userOne.address);

        //when
        await iporConfiguration.addAsset(mockAddress);

        //then
        const result = await iporConfiguration.getAssets();
        expect(result.includes(mockAddress)).to.be.true;
    });

    it("should NOT be able to add new asset when user does not have IPOR_ASSETS_ROLE role", async () => {
        //given

        await assertError(
            //when
            iporConfiguration.connect(userOne).addAsset(mockAddress),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xf2f6e1201d6fbf7ec2033ab2b3ad3dcf0ded3dd534a82806a88281c063f67656`
        );
    });

    it("should removed asset", async () => {
        //given
        const adminRole = keccak256("IPOR_ASSETS_ADMIN_ROLE");
        const role = keccak256("IPOR_ASSETS_ROLE");
        await iporConfiguration.grantRole(adminRole, admin.address);
        await iporConfiguration.grantRole(role, admin.address);
        await iporConfiguration.addAsset(mockAddress);
        const newAsset = Array.from(await iporConfiguration.getAssets());
        expect(newAsset.includes(mockAddress)).to.be.true;

        //when
        await iporConfiguration.removeAsset(mockAddress);

        //then
        const result = Array.from(await iporConfiguration.getAssets());
        expect(result.includes(mockAddress)).to.be.false;
    });

    it("should NOT be able to remove asset when user does not have IPOR_ASSETS_ROLE role", async () => {
        //given
        const role = keccak256("IPOR_ASSETS_ROLE");
        const adminRole = keccak256("IPOR_ASSETS_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin.address);
        await iporConfiguration.grantRole(role, admin.address);
        await iporConfiguration.addAsset(mockAddress);
        const newAsset = Array.from(await iporConfiguration.getAssets());
        expect(newAsset.includes(mockAddress)).to.be.true;

        await assertError(
            //when
            iporConfiguration.connect(userOne).removeAsset(mockAddress),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xf2f6e1201d6fbf7ec2033ab2b3ad3dcf0ded3dd534a82806a88281c063f67656`
        );
    });

    it("should revoke WARREN_STORAGE_ROLE role", async () => {
        //given
        const adminRole = keccak256("WARREN_STORAGE_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin.address);
        const role = keccak256("WARREN_STORAGE_ROLE");
        await iporConfiguration.grantRole(role, userOne.address);
        const shouldHasRole = await iporConfiguration.hasRole(
            role,
            userOne.address
        );
        expect(shouldHasRole).to.be.true;

        //when
        await iporConfiguration.revokeRole(role, userOne.address);

        //then
        const shouldNotHasRole = await iporConfiguration.hasRole(
            role,
            userOne.address
        );
        expect(shouldNotHasRole).to.be.false;
    });

    it("should NOT revoke WARREN_STORAGE_ROLE role, when user has not WARREN_STORAGE_ADMIN_ROLE", async () => {
        //given
        const adminRole = keccak256("WARREN_STORAGE_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin.address);
        const role = keccak256("WARREN_STORAGE_ROLE");
        await iporConfiguration.grantRole(role, userOne.address);
        const shouldHasRole = await iporConfiguration.hasRole(
            role,
            userOne.address
        );
        expect(shouldHasRole).to.be.true;

        await assertError(
            //when
            iporConfiguration
                .connect(userTwo)
                .revokeRole(role, userOne.address),

            //then
            `account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0xb1c511825e3a3673b7b3e9816a90ae950555bc6dbcfe9ddcd93d74ef23df3ed2`
        );
    });

    it("should NOT revoke ADMIN_ROLE role, when user want removed ADMIN_ROLE to himself", async () => {
        //given
        const role = keccak256("ADMIN_ROLE");
        await assertError(
            //when
            iporConfiguration.revokeRole(role, admin.address),

            //then
            "IPOR_50"
        );
    });

    it("should revoke DEFAULT_ADMIN_ROLE role", async () => {
        //given
        const role = keccak256("ADMIN_ROLE");
        await iporConfiguration.grantRole(role, userOne.address);
        const shouldHasRole = await iporConfiguration.hasRole(
            role,
            userOne.address
        );
        expect(shouldHasRole).to.be.true;

        //when
        await iporConfiguration
            .connect(userOne)
            .revokeRole(role, admin.address);

        //then
        const shouldNotHasRole = await iporConfiguration.hasRole(
            role,
            admin.address
        );
        expect(shouldNotHasRole).to.be.false;
    });

    it("should set Milton Publication Fee Transferer", async () => {
        //given
        const adminRole = keccak256(
            "MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"
        );
        await iporConfiguration.grantRole(adminRole, admin.address);
        const role = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE");
        await iporConfiguration.grantRole(role, userOne.address);

        //when
        await iporConfiguration
            .connect(userOne)
            .setMiltonPublicationFeeTransferer(mockAddress);

        //then
        const result =
            await iporConfiguration.getMiltonPublicationFeeTransferer();
        expect(mockAddress).to.be.eql(result);
    });

    it("should NOT set Milton Publication Fee Transferer when user does not have MILTON_PUBLICATION_FEE_TRANSFERER_ROLE role", async () => {
        //given

        await assertError(
            //when
            iporConfiguration
                .connect(userOne)
                .setMiltonPublicationFeeTransferer(mockAddress),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xcaf9c92ac95381198cb99b15cf6677f38c77ba44a82d424368980282298f9dc9`
        );
    });

    // TODO Add test with Timelock grant and revolk ADMIN_ROLE

    it("admin should have ADMIN_ROLE when check all roles", async () => {
        //given
        await iporConfiguration.grantRole(
            keccak256("ROLES_INFO_ADMIN_ROLE"),
            admin.address
        );
        await iporConfiguration.grantRole(
            keccak256("ROLES_INFO_ROLE"),
            admin.address
        );

        //when
        const result = await iporConfiguration.getUserRoles(admin.address);

        ///then
        expect(
            result.includes(
                "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
            )
        ).to.be.true;
    });
});
