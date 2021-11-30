const testUtils = require("./TestUtils.js");
const { ZERO_BYTES32 } = require("@openzeppelin/test-helpers/src/constants");
const { time } = require("@openzeppelin/test-helpers");
const keccak256 = require("keccak256");

const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const IporConfiguration = artifacts.require('IporConfiguration');
const MockTimelockController = artifacts.require('MockTimelockController');
const MINDELAY = time.duration.days(1);

contract('IporConfiguration', (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporConfiguration = null;
    let timelockController = null;
    const mockAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

    before(async () => {

        tokenUsdt = await UsdtMockedToken.new(testUtils.TOTAL_SUPPLY_6_DECIMALS, 6);
        tokenUsdc = await UsdcMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);

        timelockController = await MockTimelockController.new(MINDELAY, [userOne], [userTwo]);

    });

    beforeEach(async () => {
        iporConfiguration = await IporConfiguration.new();
        await iporConfiguration.grantRole(keccak256("IPOR_ASSETS_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("IPOR_ASSETS_ROLE"), admin);
        await iporConfiguration.addAsset(tokenUsdt.address);
        await iporConfiguration.addAsset(tokenDai.address);
    });

    it('should set IporAssetConfiguration for supported asset', async () => {
        //given
        const iporAssetConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenDai.address;
        await iporConfiguration.grantRole(keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("IPOR_ASSET_CONFIGURATION_ROLE"), admin);
        //when
        await iporConfiguration.setIporAssetConfiguration(asset, mockAddress);

        //then
        const actualIporAssetConfigurationAddress = await iporConfiguration.getIporAssetConfiguration(asset);
        assert(iporAssetConfigurationAddress === actualIporAssetConfigurationAddress,
            `Incorrect  IporAssetConfiguration address for asset ${asset}, actual: ${actualIporAssetConfigurationAddress}, expected: ${iporAssetConfigurationAddress}`)
    });

    it('should NOT set IporAssetConfiguration for NOT supported asset USDC', async () => {
        //given
        const iporAssetConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenUsdc.address;

        await iporConfiguration.grantRole(keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("IPOR_ASSET_CONFIGURATION_ROLE"), admin);
        //when
        await testUtils.assertError(
            //when
            iporConfiguration.setIporAssetConfiguration(asset, iporAssetConfigurationAddress),
            
            //then
            'IPOR_39'
        );
    });

    it('should NOT be able to add new asset when user does not have IPOR_ASSET_CONFIGURATION_ROLE role', async () => {
        //given
        const iporAssetConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenUsdc.address;

        await testUtils.assertError(
            //when
            iporConfiguration.setIporAssetConfiguration(asset, iporAssetConfigurationAddress, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xe8f735d503f091d7e700cae87352987ca83ec17c9b2fb176dc5a5a7ec0390360`
        );
    });

    it('should use Timelock Controller - simple case 1', async () => {
        //given

        const fnParamAddress = userThree;
        await iporConfiguration.grantRole(keccak256("MILTON_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("MILTON_ROLE"), timelockController.address);
        const calldata = await iporConfiguration.contract.methods.setMilton(fnParamAddress).encodeABI();

        //when
        await timelockController.schedule(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            { from: userOne }
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            { from: userTwo }
        );

        //then
        const actualMiltonAddress = await iporConfiguration.getMilton();

        assert(fnParamAddress === actualMiltonAddress,
            `Incorrect Milton address actual: ${actualMiltonAddress}, expected: ${fnParamAddress}`)

    });


    it('should FAIL when used Timelock Controller, when  user not exists on list of proposers', async () => {
        //given
        await iporConfiguration.grantRole(keccak256("MILTON_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("MILTON_ROLE"), timelockController.address);
        const fnParamAddress = userThree;
        const calldata = await iporConfiguration.contract.methods.setMilton(fnParamAddress).encodeABI();

        await testUtils.assertError(
            //when
            timelockController.schedule(
                iporConfiguration.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY,
                { from: userThree }
            ),
            
            //then
            'account 0x821aea9a577a9b44299b9c15c88cf3087f3b5544 is missing role 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1'
        );

    });

    it('should FAIL when used Timelock Controller, because user not exists on list of executors', async () => {
        //given
        await iporConfiguration.grantRole(keccak256("MILTON_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("MILTON_ROLE"), timelockController.address);

        const fnParamAddress = userThree;
        const calldata = await iporConfiguration.contract.methods.setMilton(fnParamAddress).encodeABI();

        await timelockController.schedule(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            { from: userOne }
        );

        await time.increase(MINDELAY);


        await testUtils.assertError(
            //when
            timelockController.execute(
                iporConfiguration.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                { from: userThree }
            ),
            
            //then
            'account 0x821aea9a577a9b44299b9c15c88cf3087f3b5544 is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63'
        );

    });

    it('should set Milton Storage', async () => {
        //given
        await iporConfiguration.grantRole(keccak256("MILTON_STORAGE_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("MILTON_STORAGE_ROLE"), admin);
        
        //when
        await iporConfiguration.setMiltonStorage(mockAddress);
        
        //then
        const result = await iporConfiguration.getMiltonStorage();
        assert(mockAddress === result);
    });

    it('should NOT set Milton storage when user does not have MILTON_STORAGE_ROLE role', async () => {
        //given

        await testUtils.assertError(
            //when
            iporConfiguration.setMiltonStorage(mockAddress),
            
            //then
            'account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0xb8f71ab818f476672f61fd76955446cd0045ed8ddb51f595d9e262b68d1157f6'
        );
    });


    it('should NOT set Milton LP Utilization Strategy when user does not have MILTON_UTILIZATION_STRATEGY role', async () => {
        //given

        await testUtils.assertError(
            //when
            iporConfiguration.setMiltonLPUtilizationStrategy(mockAddress),
            
            //then
            'account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0xef6ebe4a0a1a6329b3e5cd4d5c8731f6077174efd4f525f70490c35144b6ed72'
        );
    });

    it('should set Milton LP Utilization Strategy', async () => {
        //given
        await iporConfiguration.grantRole(keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE"), admin);
        
        //when
        await iporConfiguration.setMiltonLPUtilizationStrategy(mockAddress);
        
        //then
        const result = await iporConfiguration.getMiltonLPUtilizationStrategy();
        assert(mockAddress === result);
    });

    it('should NOT set MiltonLPUtilizationStrategy when user does not have MILTON_LP_UTILIZATION_STRATEGY_ROLE role', async () => {
        //given

        await testUtils.assertError(
            //when
            iporConfiguration.setMiltonLPUtilizationStrategy(mockAddress, { from: userOne }),
            
            //then
            'account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xef6ebe4a0a1a6329b3e5cd4d5c8731f6077174efd4f525f70490c35144b6ed72'
        );
    });

    it('should set Milton Spread Strategy', async () => {
        //given
        const role = keccak256("MILTON_SPREAD_STRATEGY_ROLE");
        const adminRole = keccak256("MILTON_SPREAD_STRATEGY_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        await iporConfiguration.grantRole(role, admin);
        
        //when
        await iporConfiguration.setMiltonSpreadStrategy(mockAddress);
        
        //then
        const result = await iporConfiguration.getMiltonSpreadStrategy();
        assert(mockAddress === result);
    });

    it('should NOT set Milton Spread Strategy when user does not have MILTON_SPREAD_STRATEGY_ROLE role', async () => {
        //given

        await testUtils.assertError(
            //when
            iporConfiguration.setMiltonSpreadStrategy(mockAddress),
            
            //then
            `account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0xdf80c0078aae521b601e4fddc35fbb2871ffaa4e22d30b53745545184b3cff3e`
        );
    });

    it('should set Warren', async () => {
        //given
        const adminRole = keccak256("WARREN_ADMIN_ROLE");
        const role = keccak256("WARREN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        await iporConfiguration.grantRole(role, admin);
        
        //when
        await iporConfiguration.setWarren(mockAddress);
        
        //then
        const result = await iporConfiguration.getWarren();
        assert(mockAddress === result);
    });

    it('should NOT set Warren because user does not have WARREN_ROLE role', async () => {
        //given

        await testUtils.assertError(
            //when
            iporConfiguration.setWarren(mockAddress),
            
            //then
            `account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0xe2062703bb72555ff94bfdd96351e7f292b8034f5f9127a25167d8d44f91ae85`
        );
    });

    it('should add new asset', async () => {
        //given
        const adminRole = keccak256("IPOR_ASSETS_ADMIN_ROLE");
        const role = keccak256("IPOR_ASSETS_ROLE");
        await iporConfiguration.grantRole(adminRole, userOne);
        await iporConfiguration.grantRole(role, userOne);
        
        //when
        await iporConfiguration.addAsset(mockAddress);
        
        //then
        const result = await iporConfiguration.getAssets();
        assert(result.includes(mockAddress));
    });

    it('should NOT be able to add new asset when user does not have IPOR_ASSETS_ROLE role', async () => {
        //given

        await testUtils.assertError(
            //when
            iporConfiguration.addAsset(mockAddress, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xf2f6e1201d6fbf7ec2033ab2b3ad3dcf0ded3dd534a82806a88281c063f67656`
        );
    });

    it('should removed asset', async () => {
        //given
        const adminRole = keccak256("IPOR_ASSETS_ADMIN_ROLE");
        const role = keccak256("IPOR_ASSETS_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        await iporConfiguration.grantRole(role, admin);
        await iporConfiguration.addAsset(mockAddress);
        const newAsset = Array.from(await iporConfiguration.getAssets());
        assert(newAsset.includes(mockAddress));
        
        //when
        await iporConfiguration.removeAsset(mockAddress);
        
        //then
        const result = Array.from(await iporConfiguration.getAssets());
        assert(!result.includes(mockAddress));
    });

    it('should NOT be able to remove asset when user does not have IPOR_ASSETS_ROLE role', async () => {
        //given
        const role = keccak256("IPOR_ASSETS_ROLE");
        const adminRole = keccak256("IPOR_ASSETS_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        await iporConfiguration.grantRole(role, admin);
        await iporConfiguration.addAsset(mockAddress);
        const newAsset = Array.from(await iporConfiguration.getAssets());
        assert(newAsset.includes(mockAddress));

        await testUtils.assertError(
            //when
            iporConfiguration.removeAsset(mockAddress, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xf2f6e1201d6fbf7ec2033ab2b3ad3dcf0ded3dd534a82806a88281c063f67656`
        );
    });

    it('should set joseph', async () => {
        //given
        const adminRole = keccak256("JOSEPH_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        const role = keccak256("JOSEPH_ROLE");
        await iporConfiguration.grantRole(role, admin);
        
        //when
        await iporConfiguration.setJoseph(mockAddress);
        
        //then
        const result = await iporConfiguration.getJoseph();
        assert(mockAddress === result);
    });

    it('should NOT set Joseph when user does not have JOSEPH_ROLE role', async () => {
        //given

        await testUtils.assertError(
            //when
            iporConfiguration.setJoseph(mockAddress),

            //then
            `account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0x2c03e103fc464998235bd7f80967993a1e6052d41cc085d3317ca8e301f51125`
        );
    });


    it('should set Warren Storage', async () => {
        //given
        const adminRole = keccak256("WARREN_STORAGE_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        const role = keccak256("WARREN_STORAGE_ROLE");
        await iporConfiguration.grantRole(role, admin);
        //when
        await iporConfiguration.setWarrenStorage(mockAddress);
        
        //then
        const result = await iporConfiguration.getWarrenStorage();
        assert(mockAddress === result);
    });

    it('should NOT set Warren Storage when user does not have JOSEPH_ROLE role', async () => {
        //given
        await testUtils.assertError(
            //when
            iporConfiguration.setWarrenStorage(mockAddress),

            //then
            `account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0xb527a07823dd490f4af143463d6cd886bd7f2ff7af38e50cce0a4d77dbccc92f`
        );
    });


    it('should revoke WARREN_STORAGE_ROLE role', async () => {
        //given
        const adminRole = keccak256("WARREN_STORAGE_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        const role = keccak256("WARREN_STORAGE_ROLE");
        await iporConfiguration.grantRole(role, userOne);
        const shouldHasRole = await iporConfiguration.hasRole(role, userOne);
        assert(shouldHasRole);
        
        //when
        await iporConfiguration.revokeRole(role, userOne);
        
        //then
        const shouldNotHasRole = await iporConfiguration.hasRole(role, userOne);
        assert(!shouldNotHasRole);
    });

    it('should NOT revoke WARREN_STORAGE_ROLE role, when user has not WARREN_STORAGE_ADMIN_ROLE', async () => {
        //given
        const adminRole = keccak256("WARREN_STORAGE_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        const role = keccak256("WARREN_STORAGE_ROLE");
        await iporConfiguration.grantRole(role, userOne);
        const shouldHasRole = await iporConfiguration.hasRole(role, userOne);
        assert(shouldHasRole);
        
        await testUtils.assertError(
            //when
            iporConfiguration.revokeRole(role, userOne, { from: userTwo }),
            
            //then
            `account 0xc5fdf4076b8f3a5357c5e395ab970b5b54098fef is missing role 0xb1c511825e3a3673b7b3e9816a90ae950555bc6dbcfe9ddcd93d74ef23df3ed2`
        );
    });

    it('should NOT revoke ADMIN_ROLE role, when user want removed ADMIN_ROLE to himself', async () => {
        //given
        const role = keccak256("ADMIN_ROLE");
        await testUtils.assertError(
            //when
            iporConfiguration.revokeRole(role, admin),
            
            //then
            'IPOR_49'
        );
    });

    it('should revoke DEFAULT_ADMIN_ROLE role', async () => {
        //given
        const role = keccak256("ADMIN_ROLE");
        await iporConfiguration.grantRole(role, userOne);
        const shouldHasRole = await iporConfiguration.hasRole(role, userOne);
        assert(shouldHasRole);
        
        //when
        await iporConfiguration.revokeRole(role, admin, { from: userOne });
        
        //then
        const shouldNotHasRole = await iporConfiguration.hasRole(role, admin);
        assert(!shouldNotHasRole);
    });

    it('should set Milton Publication Fee Transferer', async () => {
        //given
        const adminRole = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE");
        await iporConfiguration.grantRole(adminRole, admin);
        const role = keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE");
        await iporConfiguration.grantRole(role, userOne);
        
        //when
        await iporConfiguration.setMiltonPublicationFeeTransferer(mockAddress, { from: userOne });
        
        //then
        const result = await iporConfiguration.getMiltonPublicationFeeTransferer();
        assert(mockAddress === result);
    });

    it('should NOT set Milton Publication Fee Transferer when user does not have MILTON_PUBLICATION_FEE_TRANSFERER_ROLE role', async () => {
        //given

        await testUtils.assertError(
            //when
            iporConfiguration.setMiltonPublicationFeeTransferer(mockAddress, { from: userOne }),

            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xcaf9c92ac95381198cb99b15cf6677f38c77ba44a82d424368980282298f9dc9`
        );
    });

    // TODO Add test with Timelock grant and revolk ADMIN_ROLE

    it('admin should have ADMIN_ROLE when check all roles', async () => {
        //given
        await iporConfiguration.grantRole(keccak256("ROLES_INFO_ADMIN_ROLE"), admin);
        await iporConfiguration.grantRole(keccak256("ROLES_INFO_ROLE"), admin);
        
        //when
        const result = await iporConfiguration.getUserRoles(admin);

        ///then
        assert(result.includes('0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775'));
    });
});
