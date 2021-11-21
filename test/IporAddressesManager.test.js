const testUtils = require("./TestUtils.js");
const { ZERO_BYTES32 } = require("@openzeppelin/test-helpers/src/constants");
const { time } = require("@openzeppelin/test-helpers");
const keccak256 = require("keccak256");
const constants = require("@openzeppelin/test-helpers/src/constants");

const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const IporAddressesManager = artifacts.require('IporAddressesManager');
const MockTimelockController = artifacts.require('MockTimelockController');
const MINDELAY = time.duration.days(1);

contract('IporAddressesManager', (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporAddressesManager = null;
    let timelockController = null;

    before(async () => {

        tokenUsdt = await UsdtMockedToken.new(testUtils.TOTAL_SUPPLY_6_DECIMALS, 6);
        tokenUsdc = await UsdcMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);

        timelockController = await MockTimelockController.new(MINDELAY, [userOne], [userTwo]);

    });

    beforeEach(async () => {
        iporAddressesManager = await IporAddressesManager.new();
        await iporAddressesManager.grantRole(keccak256("IPOR_ASSETS_ROLE"), admin);
        await iporAddressesManager.addAsset(tokenUsdt.address);
        await iporAddressesManager.addAsset(tokenDai.address);
    });

    it('should set charlieTreasurers', async () => {
        //given
        let charlieTreasurersDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenDai.address;

        //when
        await iporAddressesManager.setCharlieTreasurer(asset, charlieTreasurersDaiAddress);

        //then
        let actualCharlieTreasurerDaiAddress = await iporAddressesManager.getCharlieTreasurer(asset);

        assert(charlieTreasurersDaiAddress === actualCharlieTreasurerDaiAddress,
            `Incorrect  Charlie Treasurer address for asset ${asset}, actual: ${actualCharlieTreasurerDaiAddress}, expected: ${charlieTreasurersDaiAddress}`)
    });

    it('should NOT set charlieTreasurers for NOT supported asset USDC', async () => {
        //given
        let address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenUsdc.address;

        //when
        await testUtils.assertError(
            //when
            iporAddressesManager.setCharlieTreasurer(asset, address),
            //then
            'IPOR_39'
        );

    });

    it('should set treasureTreasurers', async () => {
        //given
        let treasureTreasurerDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenDai.address;

        //when
        await iporAddressesManager.setTreasureTreasurer(asset, treasureTreasurerDaiAddress);

        //then
        let actualTreasureTreasurerDaiAddress = await iporAddressesManager.getTreasureTreasurer(asset);

        assert(treasureTreasurerDaiAddress === actualTreasureTreasurerDaiAddress,
            `Incorrect  Trasure Treasurer address for asset ${asset}, actual: ${actualTreasureTreasurerDaiAddress}, expected: ${treasureTreasurerDaiAddress}`)
    });

    it('should NOT set treasureTreasurers for NOT supported asset USDC', async () => {
        //given
        let address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenUsdc.address;

        //when
        await testUtils.assertError(
            //when
            iporAddressesManager.setTreasureTreasurer(asset, address),
            //then
            'IPOR_39'
        );

    });

    it('should set asset management vault', async () => {
        //given
        let address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenDai.address;

        //when
        await iporAddressesManager.setAssetManagementVault(asset, address);

        //then
        let actualAddress = await iporAddressesManager.getAssetManagementVault(asset);

        assert(address === actualAddress,
            `Incorrect  Asset Management Vault address for asset ${asset}, actual: ${actualAddress}, expected: ${address}`)
    });

    it('should NOT set asset management vault for NOT supported asset USDC', async () => {
        //given
        let address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenUsdc.address;

        //when
        await testUtils.assertError(
            //when
            iporAddressesManager.setAssetManagementVault(asset, address),
            //then
            'IPOR_39'
        );

    });

    it('should set IporConfiguration for supported asset', async () => {
        //given
        let iporConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenDai.address;

        //when
        await iporAddressesManager.setIporConfiguration(asset, iporConfigurationAddress);

        //then
        let actualIporConfigurationAddress = await iporAddressesManager.getIporConfiguration(asset);

        assert(iporConfigurationAddress === actualIporConfigurationAddress,
            `Incorrect  IporConfiguration address for asset ${asset}, actual: ${actualIporConfigurationAddress}, expected: ${iporConfigurationAddress}`)
    });

    it('should NOT set IporConfiguration for NOT supported asset USDC', async () => {
        //given
        let iporConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenUsdc.address;

        //when
        await testUtils.assertError(
            //when
            iporAddressesManager.setIporConfiguration(asset, iporConfigurationAddress),
            //then
            'IPOR_39'
        );
    });

    it('should set IpToken for supported underlying asset', async () => {
        //given
        let address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenDai.address;

        //when
        await iporAddressesManager.setIpToken(asset, address);

        //then
        let actualAddress = await iporAddressesManager.getIpToken(asset);

        assert(address === actualAddress,
            `Incorrect  ipToken address for asset ${asset}, actual: ${actualAddress}, expected: ${address}`)
    });

    it('should NOT set IpToken for NOT supported asset USDC', async () => {
        //given
        let address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenUsdc.address;

        //when
        await testUtils.assertError(
            //when
            iporAddressesManager.setIpToken(asset, address),
            //then
            'IPOR_39'
        );

    });

    it('should use Timelock Controller - simple case 1', async () => {
        //given
        await iporAddressesManager.transferOwnership(timelockController.address);

        let fnParamId = keccak256("MILTON");
        let fnParamAddress = userThree;

        let calldata = iporAddressesManager.contract.methods.setAddress(fnParamId, fnParamAddress).encodeABI();

        //when
        await timelockController.schedule(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            { from: userOne }
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            { from: userTwo }
        );

        //then
        let actualMiltonAddress = await iporAddressesManager.getAddress(fnParamId);

        assert(fnParamAddress === actualMiltonAddress,
            `Incorrect Milton address actual: ${actualMiltonAddress}, expected: ${fnParamAddress}`)

    });

    it('should FAIL when used Timelock Controller, because user not exists on list of proposers', async () => {
        //given
        await iporAddressesManager.transferOwnership(timelockController.address);

        let fnParamId = keccak256("MILTON");
        let fnParamAddress = userThree;
        let calldata = iporAddressesManager.contract.methods.setAddress(fnParamId, fnParamAddress).encodeABI();

        //when
        await testUtils.assertError(
            //when
            timelockController.schedule(
                iporAddressesManager.address,
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
        await iporAddressesManager.transferOwnership(timelockController.address);

        let fnParamId = keccak256("MILTON");
        let fnParamAddress = userThree;
        let calldata = iporAddressesManager.contract.methods.setAddress(fnParamId, fnParamAddress).encodeABI();

        await timelockController.schedule(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            { from: userOne }
        );

        await time.increase(MINDELAY);

        //when
        await testUtils.assertError(
            //when
            timelockController.execute(
                iporAddressesManager.address,
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

    it('should FAIL when used Timelock Controller, because Timelock is not an Owner of IporConfiguration smart contract', async () => {

        //given
        let fnParamId = keccak256("MILTON");
        let fnParamAddress = userThree;
        let calldata = iporAddressesManager.contract.methods.setAddress(fnParamId, fnParamAddress).encodeABI();

        await timelockController.schedule(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            { from: userOne }
        );

        await time.increase(MINDELAY);

        //when
        await testUtils.assertError(
            //when
            timelockController.execute(
                iporAddressesManager.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                { from: userTwo }
            ),
            //then
            'TimelockController: underlying transaction reverted'
        );

    });

    it('should use Timelock Controller to return ownership of IporConfiguration smart contract', async () => {
        //given
        let iporAddressesManagerOriginOwner = admin;
        await iporAddressesManager.transferOwnership(timelockController.address);

        let fnParamId = keccak256("MILTON");
        let fnParamAddress = userThree;

        let calldata = iporAddressesManager.contract.methods.transferOwnership(iporAddressesManagerOriginOwner).encodeABI();

        //First try cannot be done, because ownership is transfered to Timelock Controller
        await testUtils.assertError(
            iporAddressesManager.setAddress(fnParamId, fnParamAddress, { from: iporAddressesManagerOriginOwner }),
            'Ownable: caller is not the owner'
        );

        //when
        await timelockController.schedule(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            { from: userOne }
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            { from: userTwo }
        );

        await iporAddressesManager.setAddress(fnParamId, fnParamAddress, { from: iporAddressesManagerOriginOwner });

        //then
        let actualMiltonAddress = await iporAddressesManager.getAddress(fnParamId);

        assert(fnParamAddress === actualMiltonAddress,
            `Incorrect Milton address actual: ${actualMiltonAddress}, expected: ${fnParamAddress}`)

    });

    it('should set Milton impl', async () => {
        //given
        const miltonAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        await iporAddressesManager.grantRole(keccak256("MILTON_ROLE"), admin);
        //when
        await iporAddressesManager.setMiltonImpl(miltonAddress);
        //then
        const result = await iporAddressesManager.getMilton();
        assert(miltonAddress === result);
    });

    it('should NOT set Milton impl because user does not have MILTON_ROLE role', async () => {
        //given
        const miltonAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

    
        await testUtils.assertError(
            //when
            iporAddressesManager.setMiltonImpl(miltonAddress)
            ,
            //then
            'account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0x57a20741ae1ee76695a182cdfb995538919da5f1f6a92bca097f37a35c4be803'
        );
    });    

    it('should set Milton Storage', async () => {
        //given
        const miltonAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        await iporAddressesManager.grantRole(keccak256("MILTON_STORAGE_ROLE"), admin);
        //when
        await iporAddressesManager.setMiltonStorageImpl(miltonAddress);
        //then
        const result = await iporAddressesManager.getMiltonStorage();
        assert(miltonAddress === result);
    });

    it('should NOT set Milton storage because user does not have MILTON_STORAGE_ROLE role', async () => {
        //given
        const miltonAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

    
        await testUtils.assertError(
            //when
            iporAddressesManager.setMiltonStorageImpl(miltonAddress)
            ,
            //then
            'account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0xb8f71ab818f476672f61fd76955446cd0045ed8ddb51f595d9e262b68d1157f6'
        );
    });    



    it('should set Milton Utilization Strategy', async () => {
        //given
        const miltonAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        await iporAddressesManager.grantRole(keccak256("MILTON_UTILIZATION_STRATEGY_ROLE"), admin);
        //when
        await iporAddressesManager.setMiltonUtilizationStrategyImpl(miltonAddress);
        //then
        const result = await iporAddressesManager.getMiltonUtilizationStrategy();
        assert(miltonAddress === result);
    });

    it('should NOT set Milton Utilization Strategy because user does not have MILTON_UTILIZATION_STRATEGY role', async () => {
        //given
        const miltonAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

    
        await testUtils.assertError(
            //when
            iporAddressesManager.setMiltonUtilizationStrategyImpl(miltonAddress)
            ,
            //then
            'account 0x627306090abab3a6e1400e9345bc60c78a8bef57 is missing role 0xea07fe4bbf61e4626124decaac03ce1f9b7fc0f439c58e398dccfa7c9f00f7b9'
        );
    });   


});
