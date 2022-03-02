const { expect } = require("chai");
const { ethers } = require("hardhat");
const itParam = require("mocha-param");

const keccak256 = require("keccak256");

const roles = [
    {
        name: "ROLES_INFO_ROLE",
        adminRole: keccak256("ROLES_INFO_ADMIN_ROLE"),
        role: keccak256("ROLES_INFO_ROLE"),
    },
    {
        name: "IPOR_ASSET_CONFIGURATION_ROLE",
        adminRole: keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
        role: keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
    },
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
        name: "IPOR_ASSET_CONFIGURATION_ROLE",
        code: "0xb7659cf0d647b98a28212b8b2a17946479df7bb15e3d9c461c7d32c3536abcaf",
        role: keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
    },
    {
        name: "ROLES_INFO_ADMIN_ROLE",
        role: keccak256("ROLES_INFO_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "IPOR_ASSET_CONFIGURATION_ADMIN_ROLE",
        role: keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "ROLES_INFO_ADMIN_ROLE",
        role: keccak256("ROLES_INFO_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
];

describe("IporConfigurationRoles", () => {
    itParam(
        "should grant and revoke ${value.name}",
        roles,
        async function (value) {
            //given
            const { adminRole, role } = value;
            const IporConfiguration = await ethers.getContractFactory(
                "IporConfiguration"
            );
            const [admin, userOne, userTwo] = await ethers.getSigners();
            const iporConfiguration = await IporConfiguration.deploy();
            await iporConfiguration.deployed();
            await iporConfiguration.initialize();

            let hasAdminRole = await iporConfiguration.hasRole(
                adminRole,
                userOne.address
            );
            expect(hasAdminRole).to.be.false;

            await iporConfiguration.grantRole(adminRole, userOne.address);

            hasAdminRole = await iporConfiguration.hasRole(
                adminRole,
                userOne.address
            );
            expect(hasAdminRole).to.be.true;

            let hasRole = await iporConfiguration.hasRole(
                role,
                userTwo.address
            );
            expect(hasRole).to.be.false;

            await iporConfiguration
                .connect(userOne)
                .grantRole(role, userTwo.address);

            hasRole = await iporConfiguration.hasRole(role, userTwo.address);
            expect(hasRole).to.be.true;

            await iporConfiguration
                .connect(userOne)
                .revokeRole(role, userTwo.address);

            hasRole = await iporConfiguration.hasRole(role, userTwo.address);
            expect(hasRole).to.be.false;

            await iporConfiguration.revokeRole(adminRole, userOne.address);

            hasAdminRole = await iporConfiguration.hasRole(
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
            const { code, role } = value;
            const IporConfiguration = await ethers.getContractFactory(
                "IporConfiguration"
            );
            const [admin, userOne, userTwo] = await ethers.getSigners();
            const iporConfiguration = await IporConfiguration.deploy();
            await iporConfiguration.deployed();
            await iporConfiguration.initialize();

            await expect(
                iporConfiguration
                    .connect(userOne)
                    .grantRole(role, userTwo.address)
            ).to.be.revertedWith(code);
        }
    );
});
