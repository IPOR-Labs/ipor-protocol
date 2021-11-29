const testUtils = require("./TestUtils.js");
const keccak256 = require("keccak256");

const IporConfiguration = artifacts.require('IporConfiguration');

const IPOR_ASSETS_ADMIN_ROLE = keccak256("IPOR_ASSETS_ADMIN_ROLE");
    const MILTON_ADMIN_ROLE = keccak256("MILTON_ADMIN_ROLE");
    const MILTON_STORAGE_ADMIN_ROLE = keccak256("MILTON_STORAGE_ADMIN_ROLE");
    const MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE = keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE");
    const MILTON_SPREAD_STRATEGY_ADMIN_ROLE = keccak256("MILTON_SPREAD_STRATEGY_ADMIN_ROLE");
    const IPOR_ASSET_CONFIGURATION_ADMIN_ROLE = keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE");
    const WARREN_ADMIN_ROLE = keccak256("WARREN_ADMIN_ROLE");
    const WARREN_STORAGE_ADMIN_ROLE = keccak256("WARREN_STORAGE_ADMIN_ROLE");
    const JOSEPH_ADMIN_ROLE = keccak256("JOSEPH_ADMIN_ROLE");
    const MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE");
    const ROLES_INFO_ADMIN_ROLE = keccak256("ROLES_INFO_ADMIN_ROLE");

    const IPOR_ASSETS_ROLE = keccak256("IPOR_ASSETS_ROLE");
    const MILTON_ROLE = keccak256("MILTON_ROLE");
    const MILTON_STORAGE_ROLE = keccak256("MILTON_STORAGE_ROLE");
    const MILTON_LP_UTILIZATION_STRATEGY_ROLE = keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE");
    const MILTON_SPREAD_STRATEGY_ROLE = keccak256("MILTON_SPREAD_STRATEGY_ROLE");
    const IPOR_ASSET_CONFIGURATION_ROLE = keccak256("IPOR_ASSET_CONFIGURATION_ROLE");
    const WARREN_ROLE = keccak256("WARREN_ROLE");
    const WARREN_STORAGE_ROLE = keccak256("WARREN_STORAGE_ROLE");
    const JOSEPH_ROLE = keccak256("JOSEPH_ROLE");
    const MILTON_PUBLICATION_FEE_TRANSFERER_ROLE = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE");
    const ROLES_INFO_ROLE = keccak256("ROLES_INFO_ROLE");



contract('IporConfiguration', (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;
    beforeEach(async () => {
        iporConfiguration = await IporConfiguration.new();
    });

    it('should grant and revoke ROLES_INFO_*', async () => {
        //given
        const adminRole = keccak256("ROLES_INFO_ADMIN_ROLE");
        const role = keccak256("ROLES_INFO_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke IPOR_ASSETS_*', async () => {
        //given
        const adminRole = keccak256("IPOR_ASSETS_ADMIN_ROLE");
        const role = keccak256("IPOR_ASSETS_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke MILTON_*', async () => {
        //given
        const adminRole = keccak256("MILTON_ADMIN_ROLE");
        const role = keccak256("MILTON_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke MILTON_STORAGE_*', async () => {
        //given
        const adminRole = keccak256("MILTON_STORAGE_ADMIN_ROLE");
        const role = keccak256("MILTON_STORAGE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke MILTON_LP_UTILIZATION_STRATEGY_*', async () => {
        //given
        const adminRole = keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE");
        const role = keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke MILTON_SPREAD_STRATEGY_*', async () => {
        //given
        const adminRole = keccak256("MILTON_SPREAD_STRATEGY_ADMIN_ROLE");
        const role = keccak256("MILTON_SPREAD_STRATEGY_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke IPOR_ASSET_CONFIGURATION_*', async () => {
        //given
        const adminRole = keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE");
        const role = keccak256("IPOR_ASSET_CONFIGURATION_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke WARREN_*', async () => {
        //given
        const adminRole = keccak256("WARREN_ADMIN_ROLE");
        const role = keccak256("WARREN_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke WARREN_STORAGE_*', async () => {
        //given
        const adminRole = keccak256("WARREN_STORAGE_ADMIN_ROLE");
        const role = keccak256("WARREN_STORAGE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke JOSEPH_*', async () => {
        //given
        const adminRole = keccak256("JOSEPH_ADMIN_ROLE");
        const role = keccak256("JOSEPH_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke MILTON_PUBLICATION_FEE_TRANSFERER_*', async () => {
        //given
        const role = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE");
        const adminRole = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporConfiguration.grantRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(hasRole);

        await iporConfiguration.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporConfiguration.hasRole(role, userTwo);
        assert(!hasRole);

        await iporConfiguration.revokeRole(adminRole, userOne);

        hasAdminRole = await iporConfiguration.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should NOT be able to grant ROLES_INFO_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("ROLES_INFO_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant ROLES_INFO_ROLE role', async () => {
        //given
        const role = keccak256("ROLES_INFO_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c`
        );
    });

    it('should NOT be able to grant IPOR_ASSETS_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("IPOR_ASSETS_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant MILTON_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("MILTON_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant IPOR_ASSETS_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("IPOR_ASSETS_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant MILTON_STORAGE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("MILTON_STORAGE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant MILTON_STORAGE_ROLE role', async () => {
        //given
        const role = keccak256("MILTON_STORAGE_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x61e410eb94acd095b84b0de4a9befc42adb8e88aad1e0c387e8f14c5c05f4cd5`
        );
    });


    it('should NOT be able to grant MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant MILTON_LP_UTILIZATION_STRATEGY_ROLE role', async () => {
        //given
        const role = keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x007166265d5885631bd5886b0a89309e34f70b77bb831ac337b128950760bda7`
        );
    });


    it('should NOT be able to grant MILTON_SPREAD_STRATEGY_ROLE role', async () => {
        //given
        const role = keccak256("MILTON_SPREAD_STRATEGY_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x4a48b7c468d48efb15988e82311c6880af84ff7b6fe0e097f58073c7e794cf45`
        );
    });

    
    it('should NOT be able to grant IPOR_ASSET_CONFIGURATION_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant IPOR_ASSET_CONFIGURATION_ROLE role', async () => {
        //given
        const role = keccak256("IPOR_ASSET_CONFIGURATION_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xb7659cf0d647b98a28212b8b2a17946479df7bb15e3d9c461c7d32c3536abcaf`
        );
    });


    it('should NOT be able to grant WARREN_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("WARREN_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });
    

    it('should NOT be able to grant WARREN_ROLE role', async () => {
        //given
        const role = keccak256("WARREN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x1e04dc043068779cd91c1a75e0583a7db9c855bf85d461752231d1fe5a7f69ca`
        );
    });

    
    it('should NOT be able to grant WARREN_STORAGE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("WARREN_STORAGE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    
    it('should NOT be able to grant WARREN_STORAGE_ROLE role', async () => {
        //given
        const role = keccak256("WARREN_STORAGE_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xb1c511825e3a3673b7b3e9816a90ae950555bc6dbcfe9ddcd93d74ef23df3ed2.`
        );
    });


    it('should NOT be able to grant JOSEPH_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("JOSEPH_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant JOSEPH_ROLE role', async () => {
        //given
        const role = keccak256("JOSEPH_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x811ff4f923fc903f4390f8acf72873b5d1b288ec77b442fe124d0f95d6a53731`
        );
    });


    it('should NOT be able to grant MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant MILTON_PUBLICATION_FEE_TRANSFERER_ROLE role', async () => {
        //given
        const role = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE");

        await testUtils.assertError(
            //when
            iporConfiguration.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x7509198b389a0e4178b0935b3089a6bcebb17099877530792a238050cad1a93a`
        );
    });

});
