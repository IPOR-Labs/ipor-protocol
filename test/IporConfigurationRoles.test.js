const { expect } = require("chai");
const { ethers } = require("hardhat");
const itParam = require("mocha-param");

const keccak256 = require("keccak256");

const IPOR_ASSETS_ADMIN_ROLE = keccak256("IPOR_ASSETS_ADMIN_ROLE");
const MILTON_ADMIN_ROLE = keccak256("MILTON_ADMIN_ROLE");
const MILTON_STORAGE_ADMIN_ROLE = keccak256("MILTON_STORAGE_ADMIN_ROLE");
const MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE = keccak256(
    "MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE"
);
const MILTON_SPREAD_MODEL_ADMIN_ROLE = keccak256(
    "MILTON_SPREAD_MODEL_ADMIN_ROLE"
);
const IPOR_ASSET_CONFIGURATION_ADMIN_ROLE = keccak256(
    "IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"
);
const WARREN_ADMIN_ROLE = keccak256("WARREN_ADMIN_ROLE");
const WARREN_STORAGE_ADMIN_ROLE = keccak256("WARREN_STORAGE_ADMIN_ROLE");
const JOSEPH_ADMIN_ROLE = keccak256("JOSEPH_ADMIN_ROLE");
const MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE = keccak256(
    "MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"
);
const ROLES_INFO_ADMIN_ROLE = keccak256("ROLES_INFO_ADMIN_ROLE");

const IPOR_ASSETS_ROLE = keccak256("IPOR_ASSETS_ROLE");
const MILTON_ROLE = keccak256("MILTON_ROLE");
const MILTON_STORAGE_ROLE = keccak256("MILTON_STORAGE_ROLE");
const MILTON_LP_UTILIZATION_STRATEGY_ROLE = keccak256(
    "MILTON_LP_UTILIZATION_STRATEGY_ROLE"
);
const MILTON_SPREAD_MODEL_ROLE = keccak256("MILTON_SPREAD_MODEL_ROLE");
const IPOR_ASSET_CONFIGURATION_ROLE = keccak256(
    "IPOR_ASSET_CONFIGURATION_ROLE"
);
const WARREN_ROLE = keccak256("WARREN_ROLE");
const WARREN_STORAGE_ROLE = keccak256("WARREN_STORAGE_ROLE");
const JOSEPH_ROLE = keccak256("JOSEPH_ROLE");
const MILTON_PUBLICATION_FEE_TRANSFERER_ROLE = keccak256(
    "MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"
);
const ROLES_INFO_ROLE = keccak256("ROLES_INFO_ROLE");

const roles = [
    {
        name: "ROLES_INFO_ROLE",
        adminRole: keccak256("ROLES_INFO_ADMIN_ROLE"),
        role: keccak256("ROLES_INFO_ROLE"),
    },
    {
        name: "IPOR_ASSETS_ROLE",
        adminRole: keccak256("IPOR_ASSETS_ADMIN_ROLE"),
        role: keccak256("IPOR_ASSETS_ROLE"),
    },
    {
        name: "MILTON_ROLE",
        adminRole: keccak256("MILTON_ADMIN_ROLE"),
        role: keccak256("MILTON_ROLE"),
    },
    {
        name: "MILTON_STORAGE_ROLE",
        adminRole: keccak256("MILTON_STORAGE_ADMIN_ROLE"),
        role: keccak256("MILTON_STORAGE_ROLE"),
    },
    {
        name: "MILTON_LP_UTILIZATION_STRATEGY_ROLE",
        adminRole: keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE"),
        role: keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE"),
    },
    {
        name: "MILTON_SPREAD_MODEL_ROLE",
        adminRole: keccak256("MILTON_SPREAD_MODEL_ADMIN_ROLE"),
        role: keccak256("MILTON_SPREAD_MODEL_ROLE"),
    },
    {
        name: "IPOR_ASSET_CONFIGURATION_ROLE",
        adminRole: keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
        role: keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
    },
    {
        name: "WARREN_ROLE",
        adminRole: keccak256("WARREN_ADMIN_ROLE"),
        role: keccak256("WARREN_ROLE"),
    },
    {
        name: "WARREN_STORAGE_ROLE",
        adminRole: keccak256("WARREN_STORAGE_ADMIN_ROLE"),
        role: keccak256("WARREN_STORAGE_ROLE"),
    },
    {
        name: "JOSEPH_ROLE",
        adminRole: keccak256("JOSEPH_ADMIN_ROLE"),
        role: keccak256("JOSEPH_ROLE"),
    },
    {
        name: "MILTON_PUBLICATION_FEE_TRANSFERER_ROLE",
        adminRole: keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"),
        role: keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"),
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
        name: "IPOR_ASSETS_ROLE",
        code: "0xec35db9ce8f02d82695716c134979faf9e051eb97ef9ae15ec0aaafbde76beb5",
        role: keccak256("IPOR_ASSETS_ROLE"),
    },
    {
        name: "MILTON_ROLE",
        code: "0x1b16f266cfe5113986bbdf79323bd64ba74c9e2631c82de1297c13405226a952",
        role: keccak256("MILTON_ROLE"),
    },
    {
        name: "MILTON_STORAGE_ROLE",
        code: "0x61e410eb94acd095b84b0de4a9befc42adb8e88aad1e0c387e8f14c5c05f4cd5",
        role: keccak256("MILTON_STORAGE_ROLE"),
    },
    {
        name: "MILTON_LP_UTILIZATION_STRATEGY_ROLE",
        code: "0x007166265d5885631bd5886b0a89309e34f70b77bb831ac337b128950760bda7",
        role: keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE"),
    },
    {
        name: "MILTON_SPREAD_MODEL_ROLE",
        code: "0x869c6dda984481cbeefdaab23aeff7b5cae8e04a57bb6bc44608ea47966b45ac",
        role: keccak256("MILTON_SPREAD_MODEL_ROLE"),
    },
    {
        name: "IPOR_ASSET_CONFIGURATION_ROLE",
        code: "0xb7659cf0d647b98a28212b8b2a17946479df7bb15e3d9c461c7d32c3536abcaf",
        role: keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
    },
    {
        name: "WARREN_ROLE",
        code: "0x1e04dc043068779cd91c1a75e0583a7db9c855bf85d461752231d1fe5a7f69ca",
        role: keccak256("WARREN_ROLE"),
    },
    {
        name: "WARREN_STORAGE_ROLE",
        code: "0xb1c511825e3a3673b7b3e9816a90ae950555bc6dbcfe9ddcd93d74ef23df3ed2",
        role: keccak256("WARREN_STORAGE_ROLE"),
    },
    {
        name: "JOSEPH_ROLE",
        code: "0x811ff4f923fc903f4390f8acf72873b5d1b288ec77b442fe124d0f95d6a53731",
        role: keccak256("JOSEPH_ROLE"),
    },
    {
        name: "MILTON_PUBLICATION_FEE_TRANSFERER_ROLE",
        code: "0x7509198b389a0e4178b0935b3089a6bcebb17099877530792a238050cad1a93a",
        role: keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"),
    },
    {
        name: "ROLES_INFO_ADMIN_ROLE",
        role: keccak256("ROLES_INFO_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "IPOR_ASSETS_ADMIN_ROLE",
        role: keccak256("IPOR_ASSETS_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "MILTON_ADMIN_ROLE",
        role: keccak256("MILTON_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "MILTON_STORAGE_ADMIN_ROLE",
        role: keccak256("MILTON_STORAGE_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE",
        role: keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "MILTON_SPREAD_MODEL_ADMIN_ROLE",
        role: keccak256("MILTON_SPREAD_MODEL_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "IPOR_ASSET_CONFIGURATION_ADMIN_ROLE",
        role: keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "WARREN_ADMIN_ROLE",
        role: keccak256("WARREN_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "WARREN_STORAGE_ADMIN_ROLE",
        role: keccak256("WARREN_STORAGE_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "JOSEPH_ADMIN_ROLE",
        role: keccak256("JOSEPH_ADMIN_ROLE"),
        code: "0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775",
    },
    {
        name: "MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE",
        role: keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"),
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

            await expect(
                iporConfiguration
                    .connect(userOne)
                    .grantRole(role, userTwo.address)
            ).to.be.revertedWith(code);
        }
    );
});
