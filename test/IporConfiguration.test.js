const { expect } = require("chai");
const { ethers } = require("hardhat");
const keccak256 = require("keccak256");
const { ZERO_BYTES32 } = require("@openzeppelin/test-helpers/src/constants");
const { time } = require("@openzeppelin/test-helpers");

const { TOTAL_SUPPLY_6_DECIMALS, TOTAL_SUPPLY_18_DECIMALS, MINDELAY } = require("./Const.js");

const { assertError } = require("./Utils");

describe("IporConfiguration", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;

    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporConfiguration = null;
    let timelockController = null;
    const mockAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        const UsdtMockedToken = await ethers.getContractFactory("UsdtMockedToken");
        tokenUsdt = await UsdtMockedToken.deploy(TOTAL_SUPPLY_6_DECIMALS, 6);
        await tokenUsdt.deployed();

        const UsdcMockedToken = await ethers.getContractFactory("UsdcMockedToken");
        tokenUsdc = await UsdcMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18);
        await tokenUsdc.deployed();

        const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
        tokenDai = await DaiMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18);
        await tokenDai.deployed();
    });

    beforeEach(async () => {
        const IporConfiguration = await ethers.getContractFactory("IporConfiguration");
        iporConfiguration = await IporConfiguration.deploy();
        await iporConfiguration.deployed();
        await iporConfiguration.initialize();

        const MockTimelockController = await ethers.getContractFactory("MockTimelockController");
        timelockController = await MockTimelockController.deploy(
            MINDELAY,
            [userOne.address],
            [userTwo.address]
        );
        await timelockController.deployed();
    });

    it("should set IporAssetConfiguration for supported asset", async () => {
        //given
        const iporAssetConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
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

    it("should NOT be able to add new asset when user does not have IPOR_ASSET_CONFIGURATION_ROLE role", async () => {
        //given
        const iporAssetConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenUsdc.address;

        await assertError(
            //when
            iporConfiguration
                .connect(userOne)
                .setIporAssetConfiguration(asset, iporAssetConfigurationAddress),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xe8f735d503f091d7e700cae87352987ca83ec17c9b2fb176dc5a5a7ec0390360`
        );
    });

    it("should NOT revoke ADMIN_ROLE role, when user want removed ADMIN_ROLE to himself", async () => {
        //given
        const role = keccak256("ADMIN_ROLE");
        await assertError(
            //when
            iporConfiguration.revokeRole(role, admin.address),

            //then
            "IPOR_002"
        );
    });

    it("should revoke DEFAULT_ADMIN_ROLE role", async () => {
        //given
        const role = keccak256("ADMIN_ROLE");
        await iporConfiguration.grantRole(role, userOne.address);
        const shouldHasRole = await iporConfiguration.hasRole(role, userOne.address);
        expect(shouldHasRole).to.be.true;

        //when
        await iporConfiguration.connect(userOne).revokeRole(role, admin.address);

        //then
        const shouldNotHasRole = await iporConfiguration.hasRole(role, admin.address);
        expect(shouldNotHasRole).to.be.false;
    });

    //TODO: Add test with Timelock grant and revolk ADMIN_ROLE

    it("admin should have ADMIN_ROLE when check all roles", async () => {
        //given
        await iporConfiguration.grantRole(keccak256("ROLES_INFO_ADMIN_ROLE"), admin.address);
        await iporConfiguration.grantRole(keccak256("ROLES_INFO_ROLE"), admin.address);

        //when
        const result = await iporConfiguration.getUserRoles(admin.address);

        ///then
        expect(
            result.includes("0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775")
        ).to.be.true;
    });
});
