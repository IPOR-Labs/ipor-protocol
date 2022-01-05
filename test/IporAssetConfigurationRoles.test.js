const { expect } = require("chai");
const { ethers } = require("hardhat");
const keccak256 = require("keccak256");
const itParam = require("mocha-param");

const { TOTAL_SUPPLY_18_DECIMALS } = require("./Const.js");

const roles = [
    {
        name: "ROLES_INFO_ROLE",
        adminRole: keccak256("ROLES_INFO_ADMIN_ROLE"),
        role: keccak256("ROLES_INFO_ROLE"),
    },
    {
        name: "INCOME_TAX_PERCENTAGE_ROLE",
        adminRole: keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
        role: keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
    },
    {
        name: "OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE",
        adminRole: keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
        role: keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
    },
    {
        name: "LIQUIDATION_DEPOSIT_AMOUNT_ROLE",
        adminRole: keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE"),
        role: keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE"),
    },
    {
        name: "OPENING_FEE_PERCENTAGE_ROLE",
        adminRole: keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
        role: keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
    },
    {
        name: "IPOR_PUBLICATION_FEE_AMOUNT_ROLE",
        adminRole: keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE"),
        role: keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"),
    },
    {
        name: "LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE",
        adminRole: keccak256(
            "LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"
        ),
        role: keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"),
    },
    {
        name: "MAX_POSITION_TOTAL_AMOUNT_ROLE",
        adminRole: keccak256("MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE"),
        role: keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE"),
    },   
    {
        name: "COLLATERALIZATION_FACTOR_VALUE_ROLE",
        adminRole: keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE"),
        role: keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE"),
    },
    {
        name: "CHARLIE_TREASURER_ROLE",
        adminRole: keccak256("CHARLIE_TREASURER_ADMIN_ROLE"),
        role: keccak256("CHARLIE_TREASURER_ROLE"),
    },
    {
        name: "TREASURE_TREASURER_ROLE",
        adminRole: keccak256("TREASURE_TREASURER_ADMIN_ROLE"),
        role: keccak256("TREASURE_TREASURER_ROLE"),
    },
    {
        name: "ASSET_MANAGEMENT_VAULT_ROLE",
        adminRole: keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE"),
        role: keccak256("ASSET_MANAGEMENT_VAULT_ROLE"),
    },
    {
        name: "DECAY_FACTOR_VALUE_ROLE",
        adminRole: keccak256("DECAY_FACTOR_VALUE_ADMIN_ROLE"),
        role: keccak256("DECAY_FACTOR_VALUE_ROLE"),
    },   
];

const rolesNotGrant = [
    {
        name: "ROLES_INFO_ROLE",
        code: "0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c",
        role: keccak256("ROLES_INFO_ROLE"),
    },
    {
        name: "INCOME_TAX_PERCENTAGE_ROLE",
        code: "0xcaa6983304bafc9d674310f90270b5949e0bb6e51e706428584d7da457ddeccd",
        role: keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
    },
    {
        name: "OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE",
        code: "0xebe66983650b4d8b57cb18fe7c97cdfe49625e06d8c6e70e646beb3a8ae73dd6",
        role: keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
    },
    {
        name: "LIQUIDATION_DEPOSIT_AMOUNT_ROLE",
        code: "0xe7cc2a3bd9f3d49de9396c60dc8e9969986ea020b9bf72f8ab3527c64c7cbcf3",
        role: keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE"),
    },
    {
        name: "OPENING_FEE_PERCENTAGE_ROLE",
        code: "0x8714c5b454a0d07dd83274b33d478ceb04fb8767fe2079073b335f6e3a9feb14",
        role: keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
    },
    {
        name: "IPOR_PUBLICATION_FEE_AMOUNT_ROLE",
        code: "0x789f25814c078f5d3a73f07837d3717096a7f31ff58dc1f3971a1aed3a8054d0",
        role: keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"),
    },
    {
        name: "LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE",
        code: "0x9390cd14c303a3aaaa87f1f63728f95f237300898d55577f06a9b2f83904e4bd",
        role: keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"),
    },
    {
        name: "MAX_POSITION_TOTAL_AMOUNT_ROLE",
        code: "0x7c8d8e1bbd6d112e40e3f26d08aabeb9e7e37771bd3877eb3850332e23f7c782",
        role: keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE"),
    },
    
    {
        name: "COLLATERALIZATION_FACTOR_VALUE_ROLE",
        code: "0xc73b383cc34ef691c51adf836f82981b87c968081f10ae91077611045805b35e",
        role: keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE"),
    },
    {
        name: "CHARLIE_TREASURER_ROLE",
        code: "0x0a8c46bed2194419383260fcc83e7085079a16a3dce173fb3d66eb1f81c71f6e",
        role: keccak256("CHARLIE_TREASURER_ROLE"),
    },
    {
        name: "TREASURE_TREASURER_ROLE",
        code: "0x1ba824e22ad2e0dc1d7a152742f3b5890d88c5a849ed8e57f4c9d84203d3ea9c",
        role: keccak256("TREASURE_TREASURER_ROLE"),
    },
    {
        name: "ASSET_MANAGEMENT_VAULT_ROLE",
        code: "0x1d3c5c61c32255cb922b09e735c0e9d76d2aacc424c3f7d9b9b85c478946fa26",
        role: keccak256("ASSET_MANAGEMENT_VAULT_ROLE"),
    },
    {
        name: "DECAY_FACTOR_VALUE_ROLE",
        code: "0xed044c57d37423bb4623f9110729ee31cae04cae931fe5ab3b24fc2e474fbb70",
        role: keccak256("DECAY_FACTOR_VALUE_ROLE"),
    },    
    {
        name: "ROLES_INFO_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("ROLES_INFO_ADMIN_ROLE"),
    },
    {
        name: "INCOME_TAX_PERCENTAGE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
    },
    {
        name: "OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
    },
    {
        name: "LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE"),
    },
    {
        name: "OPENING_FEE_PERCENTAGE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
    },
    {
        name: "IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE"),
    },
    {
        name: "LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
    },
    {
        name: "MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE"),
    },    
    {
        name: "COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE"),
    },
    {
        name: "CHARLIE_TREASURER_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("CHARLIE_TREASURER_ADMIN_ROLE"),
    },
    {
        name: "TREASURE_TREASURER_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("TREASURE_TREASURER_ADMIN_ROLE"),
    },
    {
        name: "ASSET_MANAGEMENT_VAULT_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE"),
    },
    {
        name: "DECAY_FACTOR_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("DECAY_FACTOR_VALUE_ADMIN_ROLE"),
    },    
];

describe("IporAssetConfigurationRoles", () => {
    itParam(
        "should grant and revoke ${value.name}",
        roles,
        async function (value) {
            //given
            const { adminRole, role } = value;
            const DaiMockedToken = await ethers.getContractFactory(
                "DaiMockedToken"
            );
            const tokenDai = await DaiMockedToken.deploy(
                TOTAL_SUPPLY_18_DECIMALS,
                18
            );
            await tokenDai.deployed();

            const IpToken = await ethers.getContractFactory("IpToken");
            const ipTokenDai = await IpToken.deploy(
                tokenDai.address,
                "IP DAI",
                "ipDAI"
            );
            await ipTokenDai.deployed();

            const IporAssetConfiguration = await ethers.getContractFactory(
                "IporAssetConfiguration"
            );
            const [admin, userOne, userTwo] = await ethers.getSigners();
            const iporAssetConfiguration = await IporAssetConfiguration.deploy(
                tokenDai.address,
                ipTokenDai.address
            );
            await iporAssetConfiguration.deployed();

            let hasAdminRole = await iporAssetConfiguration.hasRole(
                adminRole,
                userOne.address
            );
            expect(hasAdminRole).to.be.false;

            await iporAssetConfiguration.grantRole(adminRole, userOne.address);

            hasAdminRole = await iporAssetConfiguration.hasRole(
                adminRole,
                userOne.address
            );
            expect(hasAdminRole).to.be.true;

            let hasRole = await iporAssetConfiguration.hasRole(
                role,
                userTwo.address
            );
            expect(hasRole).to.be.false;

            await iporAssetConfiguration
                .connect(userOne)
                .grantRole(role, userTwo.address);

            hasRole = await iporAssetConfiguration.hasRole(
                role,
                userTwo.address
            );
            expect(hasRole).to.be.true;

            await iporAssetConfiguration
                .connect(userOne)
                .revokeRole(role, userTwo.address);

            hasRole = await iporAssetConfiguration.hasRole(
                role,
                userTwo.address
            );
            expect(hasRole).to.be.false;

            await iporAssetConfiguration.revokeRole(adminRole, userOne.address);

            hasAdminRole = await iporAssetConfiguration.hasRole(
                adminRole,
                userOne.address
            );
            expect(hasAdminRole).to.be.false;
        }
    );

    itParam(
        "should not be able to grant role ${value.name}",
        rolesNotGrant,
        async function (value) {
            const { role, code } = value;
            const DaiMockedToken = await ethers.getContractFactory(
                "DaiMockedToken"
            );
            const tokenDai = await DaiMockedToken.deploy(
                TOTAL_SUPPLY_18_DECIMALS,
                18
            );
            await tokenDai.deployed();

            const IpToken = await ethers.getContractFactory("IpToken");
            const ipTokenDai = await IpToken.deploy(
                tokenDai.address,
                "IP DAI",
                "ipDAI"
            );
            await ipTokenDai.deployed();

            const IporAssetConfiguration = await ethers.getContractFactory(
                "IporAssetConfiguration"
            );
            const [admin, userOne, userTwo] = await ethers.getSigners();
            const iporAssetConfiguration = await IporAssetConfiguration.deploy(
                tokenDai.address,
                ipTokenDai.address
            );
            await iporAssetConfiguration.deployed();

            await expect(
                iporAssetConfiguration
                    .connect(userOne)
                    .grantRole(role, userTwo.address)
            ).to.be.revertedWith(code);
        }
    );
});
