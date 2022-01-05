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

describe("MiltonSpreadConfiguration", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;

    let tokenDai = null;
    let ipTokenDai = null;
    let iporAssetConfigurationDAI = null;
    let timelockController = null;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
    });

    beforeEach(async () => {
        const MiltonSpreadConfiguration = await ethers.getContractFactory(
            "MiltonSpreadConfiguration"
        );
        miltonSpreadConfiguration = await MiltonSpreadConfiguration.deploy();
        miltonSpreadConfiguration.deployed();
    });

    it("should set demandComponentKfValue", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");
        await miltonSpreadConfiguration.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE");
        await miltonSpreadConfiguration.grantRole(role, userOne.address);

        //when
        await miltonSpreadConfiguration
            .connect(userOne)
            .setDemandComponentKfValue(expectedValue);

        //then
        const actualValue = BigInt(
            await miltonSpreadConfiguration.getSpreadDemandComponentKfValue()
        );

        expect(expectedValue).to.be.eql(actualValue);
    });

    it("should NOT set demandComponentKfValue when user does not have SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE role", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");

        await assertError(
            //when
            miltonSpreadConfiguration
                .connect(userOne)
                .setDemandComponentKfValue(expectedValue),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xa3398f01fb1ec4a3bb19698f87225bd824cc0c1d4f362a6b56fddc0006bab61f`
        );
    });

    it("should set demandComponentLambdaValue", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");
        await miltonSpreadConfiguration.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE");
        await miltonSpreadConfiguration.grantRole(role, userOne.address);

        //when
        await miltonSpreadConfiguration
            .connect(userOne)
            .setDemandComponentLambdaValue(expectedValue);

        //then
        const actualValue = BigInt(
            await miltonSpreadConfiguration.getSpreadDemandComponentLambdaValue()
        );

        expect(expectedValue).to.be.eql(actualValue);
    });

    it("should NOT set demandComponentLambdaValue when user does not have SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE role", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");

        await assertError(
            //when
            miltonSpreadConfiguration
                .connect(userOne)
                .setDemandComponentLambdaValue(expectedValue),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xbb8358898740bf199fac3e7b605f7a84a5fc0ea3d3b35788eb6bdbea68564eb3`
        );
    });

    it("should set demandComponentKOmegaValue", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");
        await miltonSpreadConfiguration.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE");
        await miltonSpreadConfiguration.grantRole(role, userOne.address);

        //when
        await miltonSpreadConfiguration
            .connect(userOne)
            .setDemandComponentKOmegaValue(expectedValue);

        //then
        const actualValue = BigInt(
            await miltonSpreadConfiguration.getSpreadDemandComponentKOmegaValue()
        );

        expect(expectedValue).to.be.eql(actualValue);
    });

    it("should NOT set demandComponentKOmegaValue when user does not have SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE role", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");

        await assertError(
            //when
            miltonSpreadConfiguration
                .connect(userOne)
                .setDemandComponentKOmegaValue(expectedValue),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x637ba89bee1cd75c66353215d464266e9edf15bc34e82be6a9605aac890faa3d`
        );
    });

    it("should set demandComponentMaxLiquidityRedemptionValue", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");
        await miltonSpreadConfiguration.grantRole(
            keccak256(
                "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE"
            ),
            admin.address
        );
        const role = keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE"
        );
        await miltonSpreadConfiguration.grantRole(role, userOne.address);

        //when
        await miltonSpreadConfiguration
            .connect(userOne)
            .setDemandComponentMaxLiquidityRedemptionValue(expectedValue);

        //then
        const actualValue = BigInt(
            await miltonSpreadConfiguration.getSpreadDemandComponentMaxLiquidityRedemptionValue()
        );

        expect(expectedValue).to.be.eql(actualValue);
    });

    it("should NOT set demandComponentMaxLiquidityRedemptionValue when user does not have SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE role", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");

        await assertError(
            //when
            miltonSpreadConfiguration
                .connect(userOne)
                .setDemandComponentMaxLiquidityRedemptionValue(expectedValue),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x43a301f724eae1c60a7593d4009d0bd802b80e0d4a26c035422902546f1f9ba2`
        );
    });

    it("should set atParComponentKVolValue", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");
        await miltonSpreadConfiguration.grantRole(
            keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE");
        await miltonSpreadConfiguration.grantRole(role, userOne.address);

        //when
        await miltonSpreadConfiguration
            .connect(userOne)
            .setAtParComponentKVolValue(expectedValue);

        //then
        const actualValue = BigInt(
            await miltonSpreadConfiguration.getSpreadAtParComponentKVolValue()
        );

        expect(expectedValue).to.be.eql(actualValue);
    });

    it("should NOT set atParComponentKVolValue when user does not have SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE role", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");

        await assertError(
            //when
            miltonSpreadConfiguration
                .connect(userOne)
                .setAtParComponentKVolValue(expectedValue),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xe02d1051d198d59b76e4b27810e664ce05ce9051dd63960cd3091a729a082b2e`
        );
    });

    it("should set atParComponentKHistValue", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");
        await miltonSpreadConfiguration.grantRole(
            keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE");
        await miltonSpreadConfiguration.grantRole(role, userOne.address);

        //when
        await miltonSpreadConfiguration
            .connect(userOne)
            .setAtParComponentKHistValue(expectedValue);

        //then
        const actualValue = BigInt(
            await miltonSpreadConfiguration.getSpreadAtParComponentKHistValue()
        );

        expect(expectedValue).to.be.eql(actualValue);
    });

    it("should NOT set atParComponentKHistValue when user does not have SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE role", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");

        await assertError(
            //when
            miltonSpreadConfiguration
                .connect(userOne)
                .setAtParComponentKHistValue(expectedValue),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xdca8835bfc38d693c83ccb0c5ce40acbfb459373479e6f00daf593e9050c9cf3`
        );
    });

    it("should set spreadMaxValue", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");
        await miltonSpreadConfiguration.grantRole(
            keccak256("SPREAD_MAX_VALUE_ADMIN_ROLE"),
            admin.address
        );
        const role = keccak256("SPREAD_MAX_VALUE_ROLE");
        await miltonSpreadConfiguration.grantRole(role, userOne.address);

        //when
        await miltonSpreadConfiguration
            .connect(userOne)
            .setSpreadMaxValue(expectedValue);

        //then
        const actualValue = BigInt(
            await miltonSpreadConfiguration.getSpreadMaxValue()
        );

        expect(expectedValue).to.be.eql(actualValue);
    });

    it("should NOT set spreadMaxValue when user does not have SPREAD_MAX_VALUE_ROLE role", async () => {
        //given
        const expectedValue = BigInt("1234000000000000000000");

        await assertError(
            //when
            miltonSpreadConfiguration
                .connect(userOne)
                .setSpreadMaxValue(expectedValue),

            //then
            `account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x243c66f877d2b9250ad8706721efad9f4b3d65a4b61cc21d637d7bfe5d73f574`
        );
    });
});
