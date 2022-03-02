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
];

const rolesNotGrant = [
    {
        name: "ROLES_INFO_ROLE",
        code: "0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c",
        role: keccak256("ROLES_INFO_ROLE"),
    },
    {
        name: "ROLES_INFO_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("ROLES_INFO_ADMIN_ROLE"),
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
            const iporAssetConfiguration =
                await IporAssetConfiguration.deploy();
            await iporAssetConfiguration.deployed();
            await iporAssetConfiguration.initialize(
                tokenDai.address,
                ipTokenDai.address
            );

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
            const iporAssetConfiguration =
                await IporAssetConfiguration.deploy();
            await iporAssetConfiguration.deployed();
            await iporAssetConfiguration.initialize(
                tokenDai.address,
                ipTokenDai.address
            );

            await expect(
                iporAssetConfiguration
                    .connect(userOne)
                    .grantRole(role, userTwo.address)
            ).to.be.revertedWith(code);
        }
    );
});
