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
        name: "SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE",
        adminRole: keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE"),
        role: keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE"),
    },
    {
        name: "SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE",
        adminRole: keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE"),
        role: keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE"),
    },
    {
        name: "SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE",
        adminRole: keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE"),
        role: keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE"),
    },
    {
        name: "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE",
        adminRole: keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE"
        ),
        role: keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE"
        ),
    },
    {
        name: "SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE",
        adminRole: keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE"),
        role: keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE"),
    },
    {
        name: "SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE",
        adminRole: keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE"),
        role: keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE"),
    },
    {
        name: "SPREAD_MAX_VALUE_ROLE",
        adminRole: keccak256("SPREAD_MAX_VALUE_ADMIN_ROLE"),
        role: keccak256("SPREAD_MAX_VALUE_ROLE"),
    },
];

const rolesNotGrant = [
    {
        name: "ROLES_INFO_ROLE",
        code: "0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c",
        role: keccak256("ROLES_INFO_ROLE"),
    },

    {
        name: "SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE",
        code: "0x535fa1a8b46c5ac24ca523a0fecbea2eef851695b9833f8ec25b9296a155a55e",
        role: keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE"),
    },

    {
        name: "SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE",
        code: "0x266e1cccbc57d946f8878e0ccafeaa12db3490531747e2ee4f3436f9a2b2fa6e",
        role: keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE"),
    },

    {
        name: "SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE",
        code: "0x8a92933037b88f51a66db44f2de47a243ede378bceacc6b5f0cf5fea0e402c47",
        role: keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE"),
    },

    {
        name: "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE",
        code: "0xc06556706d5d60c0be16d3efe62591e2c93ad537438fd1d9e36cba7a7dfe614f",
        role: keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE"
        ),
    },
    {
        name: "SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE",
        code: "0x7b2e8d4d108e2a713ab6896f8a6c0eb773e393fdd0615487081410722d9217da",
        role: keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE"),
    },

    {
        name: "SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE",
        code: "0x4c36addcf0f2c8cd7f8f3a0ef18f7269079c8b77cc782aad8793b387b282e235",
        role: keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE"),
    },

    {
        name: "SPREAD_MAX_VALUE_ROLE",
        code: "0xb581f555a22f011e62b435ab4668283f41a911882c41e2508f9bc9c258b30ecf",
        role: keccak256("SPREAD_MAX_VALUE_ROLE"),
    },

    {
        name: "SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE"),
    },

    {
        name: "SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE"),
    },

    {
        name: "SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE"),
    },

    {
        name: "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE"
        ),
    },
    {
        name: "SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE"),
    },

    {
        name: "SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE"),
    },

    {
        name: "SPREAD_MAX_VALUE_ADMIN_ROLE",
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
        role: keccak256("SPREAD_MAX_VALUE_ADMIN_ROLE"),
    },
];

describe("MiltonSpreadConfigurationRoles", () => {
    itParam(
        "should grant and revoke ${value.name}",
        roles,
        async function (value) {
            //given
            const { adminRole, role } = value;

            const MiltonSpreadConfiguration = await ethers.getContractFactory(
                "MiltonSpreadConfiguration"
            );
            const [admin, userOne, userTwo] = await ethers.getSigners();
            const miltonSpreadConfiguration =
                await MiltonSpreadConfiguration.deploy();

            await miltonSpreadConfiguration.deployed();

            let hasAdminRole = await miltonSpreadConfiguration.hasRole(
                adminRole,
                userOne.address
            );
            expect(hasAdminRole).to.be.false;

            await miltonSpreadConfiguration.grantRole(
                adminRole,
                userOne.address
            );

            hasAdminRole = await miltonSpreadConfiguration.hasRole(
                adminRole,
                userOne.address
            );
            expect(hasAdminRole).to.be.true;

            let hasRole = await miltonSpreadConfiguration.hasRole(
                role,
                userTwo.address
            );
            expect(hasRole).to.be.false;

            await miltonSpreadConfiguration
                .connect(userOne)
                .grantRole(role, userTwo.address);

            hasRole = await miltonSpreadConfiguration.hasRole(
                role,
                userTwo.address
            );
            expect(hasRole).to.be.true;

            await miltonSpreadConfiguration
                .connect(userOne)
                .revokeRole(role, userTwo.address);

            hasRole = await miltonSpreadConfiguration.hasRole(
                role,
                userTwo.address
            );
            expect(hasRole).to.be.false;

            await miltonSpreadConfiguration.revokeRole(
                adminRole,
                userOne.address
            );

            hasAdminRole = await miltonSpreadConfiguration.hasRole(
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

            const MiltonSpreadConfiguration = await ethers.getContractFactory(
                "MiltonSpreadConfiguration"
            );
            const [admin, userOne, userTwo] = await ethers.getSigners();
            const miltonSpreadConfiguration =
                await MiltonSpreadConfiguration.deploy();
            await miltonSpreadConfiguration.deployed();

            await expect(
                miltonSpreadConfiguration
                    .connect(userOne)
                    .grantRole(role, userTwo.address)
            ).to.be.revertedWith(code);
        }
    );
});
