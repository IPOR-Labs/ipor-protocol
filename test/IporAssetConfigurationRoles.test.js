const testUtils = require("./TestUtils.js");
const { ZERO_BYTES32 } = require("@openzeppelin/test-helpers/src/constants");
const { time } = require("@openzeppelin/test-helpers");
const keccak256 = require("keccak256");

const DaiMockedToken = artifacts.require('DaiMockedToken');
const IporAssetConfigurationDai = artifacts.require('IporAssetConfigurationDai');
const IpToken = artifacts.require('IpToken');
const MockTimelockController = artifacts.require('MockTimelockController');
const MINDELAY = time.duration.days(1);

contract('IporAssetConfiguration', (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let tokenDai = null;
    let ipTokenDai = null;
    let iporAssetConfigurationDAI = null;

    before(async () => {
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        ipTokenDai = await IpToken.new(tokenDai.address, "IP DAI", "ipDAI");
    });

    beforeEach(async () => {
        iporAssetConfigurationDAI = await IporAssetConfigurationDai.new(tokenDai.address, ipTokenDai.address);
    });

    it('should grant and revoke ROLES_INFO_*', async () => {
        //given
        const adminRole = keccak256("ROLES_INFO_ADMIN_ROLE");
        const role = keccak256("ROLES_INFO_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });
 

    it('should grant and revoke INCOME_TAX_PERCENTAGE_*', async () => {
        //given
        const adminRole = keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE");
        const role = keccak256("INCOME_TAX_PERCENTAGE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });
 
    it('should grant and revoke OPENING_FEE_FOR_TREASURY_PERCENTAGE_*', async () => {
        //given
        const adminRole = keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE");
        const role = keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke LIQUIDATION_DEPOSIT_AMOUNT_*', async () => {
        //given
        const adminRole = keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE");
        const role = keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke OPENING_FEE_PERCENTAGE_*', async () => {
        //given
        const adminRole = keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE");
        const role = keccak256("OPENING_FEE_PERCENTAGE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke IPOR_PUBLICATION_FEE_AMOUNT_*', async () => {
        //given
        const adminRole = keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE");
        const role = keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_*', async () => {
        //given
        const adminRole = keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE");
        const role = keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke MAX_POSITION_TOTAL_AMOUNT_*', async () => {
        //given
        const adminRole = keccak256("MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE");
        const role = keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke SPREAD_PAY_FIXED_VALUE_*', async () => {
        //given
        const adminRole = keccak256("SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE");
        const role = keccak256("SPREAD_PAY_FIXED_VALUE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke SPREAD_REC_FIXED_VALUE_*', async () => {
        //given
        const adminRole = keccak256("SPREAD_REC_FIXED_VALUE_ADMIN_ROLE");
        const role = keccak256("SPREAD_REC_FIXED_VALUE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke COLLATERALIZATION_FACTOR_VALUE_*', async () => {
        //given
        const adminRole = keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE");
        const role = keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke CHARLIE_TREASURER_*', async () => {
        //given
        const adminRole = keccak256("CHARLIE_TREASURER_ADMIN_ROLE");
        const role = keccak256("CHARLIE_TREASURER_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke TREASURE_TREASURER_*', async () => {
        //given
        const adminRole = keccak256("TREASURE_TREASURER_ADMIN_ROLE");
        const role = keccak256("TREASURE_TREASURER_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should grant and revoke ASSET_MANAGEMENT_VAULT_*', async () => {
        //given
        const adminRole = keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE");
        const role = keccak256("ASSET_MANAGEMENT_VAULT_ROLE");

        // userOne has granted adminRole
        // userTwo has granted role
        // userTwo has revoke role
        // userOne has revoke adminRole 

        let hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);

        await iporAssetConfigurationDAI.grantRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(hasAdminRole);

        let hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.grantRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(hasRole);

        await iporAssetConfigurationDAI.revokeRole(role, userTwo, {from: userOne});

        hasRole = await iporAssetConfigurationDAI.hasRole(role, userTwo);
        assert(!hasRole);

        await iporAssetConfigurationDAI.revokeRole(adminRole, userOne);

        hasAdminRole = await iporAssetConfigurationDAI.hasRole(adminRole, userOne);
        assert(!hasAdminRole);
    });

    it('should NOT be able to grant ROLES_INFO_ROLE role', async () => {
        //given
        const role = keccak256("ROLES_INFO_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c`
        );
    });

    it('should NOT be able to grant ROLES_INFO_ROLE role', async () => {
        //given
        const role = keccak256("ROLES_INFO_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant INCOME_TAX_PERCENTAGE_ROLE role', async () => {
        //given
        const role = keccak256("INCOME_TAX_PERCENTAGE_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xcaa6983304bafc9d674310f90270b5949e0bb6e51e706428584d7da457ddeccd`
        );
    });

    it('should NOT be able to grant INCOME_TAX_PERCENTAGE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });


    it('should NOT be able to grant OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE role', async () => {
        //given
        const role = keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xebe66983650b4d8b57cb18fe7c97cdfe49625e06d8c6e70e646beb3a8ae73dd6`
        );
    });

    it('should NOT be able to grant OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant LIQUIDATION_DEPOSIT_AMOUNT_ROLE role', async () => {
        //given
        const role = keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xe7cc2a3bd9f3d49de9396c60dc8e9969986ea020b9bf72f8ab3527c64c7cbcf3`
        );
    });

    it('should NOT be able to grant LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant OPENING_FEE_PERCENTAGE_ROLE role', async () => {
        //given
        const role = keccak256("OPENING_FEE_PERCENTAGE_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x8714c5b454a0d07dd83274b33d478ceb04fb8767fe2079073b335f6e3a9feb14`
        );
    });

    it('should NOT be able to grant OPENING_FEE_PERCENTAGE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant IPOR_PUBLICATION_FEE_AMOUNT_ROLE role', async () => {
        //given
        const role = keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x789f25814c078f5d3a73f07837d3717096a7f31ff58dc1f3971a1aed3a8054d0`
        );
    });

    it('should NOT be able to grant IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE role', async () => {
        //given
        const role = keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x9390cd14c303a3aaaa87f1f63728f95f237300898d55577f06a9b2f83904e4bd`
        );
    });    

    it('should NOT be able to grant LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant MAX_POSITION_TOTAL_AMOUNT_ROLE role', async () => {
        //given
        const role = keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x7c8d8e1bbd6d112e40e3f26d08aabeb9e7e37771bd3877eb3850332e23f7c782`
        );
    });

    it('should NOT be able to grant MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant SPREAD_PAY_FIXED_VALUE_ROLE role', async () => {
        //given
        const role = keccak256("SPREAD_PAY_FIXED_VALUE_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x25c5c866e37916853ee1e8f7a6086f59f8a91e8d956b88c76e2da4a4757464a5`
        );
    });

    it('should NOT be able to grant SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant SPREAD_REC_FIXED_VALUE_ROLE role', async () => {
        //given
        const role = keccak256("SPREAD_REC_FIXED_VALUE_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xe7ab403030c879418b4aa67684f7df144efdfece247774c9ad62a204ee842e47`
        );
    });

    it('should NOT be able to grant SPREAD_REC_FIXED_VALUE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("SPREAD_REC_FIXED_VALUE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant COLLATERALIZATION_FACTOR_VALUE_ROLE role', async () => {
        //given
        const role = keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xc73b383cc34ef691c51adf836f82981b87c968081f10ae91077611045805b35e`
        );
    });

    it('should NOT be able to grant COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant CHARLIE_TREASURER_ROLE role', async () => {
        //given
        const role = keccak256("CHARLIE_TREASURER_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x0a8c46bed2194419383260fcc83e7085079a16a3dce173fb3d66eb1f81c71f6e`
        );
    });

    it('should NOT be able to grant CHARLIE_TREASURER_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("CHARLIE_TREASURER_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant TREASURE_TREASURER_ROLE role', async () => {
        //given
        const role = keccak256("TREASURE_TREASURER_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x1ba824e22ad2e0dc1d7a152742f3b5890d88c5a849ed8e57f4c9d84203d3ea9c`
        );
    });

    it('should NOT be able to grant TREASURE_TREASURER_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("TREASURE_TREASURER_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

    it('should NOT be able to grant ASSET_MANAGEMENT_VAULT_ROLE role', async () => {
        //given
        const role = keccak256("ASSET_MANAGEMENT_VAULT_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x1d3c5c61c32255cb922b09e735c0e9d76d2aacc424c3f7d9b9b85c478946fa26`
        );
    });

    it('should NOT be able to grant ASSET_MANAGEMENT_VAULT_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.grantRole(role, userTwo, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775`
        );
    });

});
