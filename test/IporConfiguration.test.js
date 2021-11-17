const testUtils = require("./TestUtils.js");
const {ZERO_BYTES32} = require("@openzeppelin/test-helpers/src/constants");
const {time} = require("@openzeppelin/test-helpers");
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

    before(async () => {

        tokenUsdt = await UsdtMockedToken.new(testUtils.TOTAL_SUPPLY_6_DECIMALS, 6);
        tokenUsdc = await UsdcMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);

        timelockController = await MockTimelockController.new(MINDELAY, [userOne], [userTwo]);

    });

    beforeEach(async () => {
        iporConfiguration = await IporConfiguration.new();
        await iporConfiguration.addAsset(tokenUsdt.address);
        await iporConfiguration.addAsset(tokenDai.address);
    });

    it('should set IporAssetConfiguration for supported asset', async () => {
        //given
        let iporAssetConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenDai.address;

        //when
        await iporConfiguration.setIporAssetConfiguration(asset, iporAssetConfigurationAddress);

        //then
        let actualIporAssetConfigurationAddress = await iporConfiguration.getIporAssetConfiguration(asset);

        assert(iporAssetConfigurationAddress === actualIporAssetConfigurationAddress,
            `Incorrect  IporAssetConfiguration address for asset ${asset}, actual: ${actualIporAssetConfigurationAddress}, expected: ${iporAssetConfigurationAddress}`)
    });

    it('should NOT set IporAssetConfiguration for NOT supported asset USDC', async () => {
        //given
        let iporAssetConfigurationAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenUsdc.address;

        //when
        await testUtils.assertError(
            //when
            iporConfiguration.setIporAssetConfiguration(asset, iporAssetConfigurationAddress),
            //then
            'IPOR_39'
        );
    });

    it('should use Timelock Controller - simple case 1', async () => {
        //given
        await iporConfiguration.transferOwnership(timelockController.address);

        let fnParamAddress = userThree;

        let calldata = await iporConfiguration.contract.methods.setMilton(fnParamAddress).encodeABI();

        //when
        await timelockController.schedule(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            {from: userTwo}
        );

        //then
        let actualMiltonAddress = await iporConfiguration.getMilton();

        assert(fnParamAddress === actualMiltonAddress,
            `Incorrect Milton address actual: ${actualMiltonAddress}, expected: ${fnParamAddress}`)

    });

    it('should FAIL when used Timelock Controller, because user not exists on list of proposers', async () => {
        //given
        await iporConfiguration.transferOwnership(timelockController.address);

        let fnParamAddress = userThree;
        let calldata = await iporConfiguration.contract.methods.setMilton(fnParamAddress).encodeABI();

        //when
        await testUtils.assertError(
            //when
            timelockController.schedule(
                iporConfiguration.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY,
                {from: userThree}
            ),
            //then
            'account 0x821aea9a577a9b44299b9c15c88cf3087f3b5544 is missing role 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1'
        );

    });

    it('should FAIL when used Timelock Controller, because user not exists on list of executors', async () => {
        //given
        await iporConfiguration.transferOwnership(timelockController.address);

        let fnParamAddress = userThree;
        let calldata = await iporConfiguration.contract.methods.setMilton(fnParamAddress).encodeABI();

        await timelockController.schedule(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        //when
        await testUtils.assertError(
            //when
            timelockController.execute(
                iporConfiguration.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                {from: userThree}
            ),
            //then
            'account 0x821aea9a577a9b44299b9c15c88cf3087f3b5544 is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63'
        );

    });

    it('should FAIL when used Timelock Controller, because Timelock is not an Owner of IporAssetConfiguration smart contract', async () => {

        //given
        let fnParamAddress = userThree;
        let calldata = await iporConfiguration.contract.methods.setMilton(fnParamAddress).encodeABI();

        await timelockController.schedule(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        //when
        await testUtils.assertError(
            //when
            timelockController.execute(
                iporConfiguration.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                {from: userTwo}
            ),
            //then
            'TimelockController: underlying transaction reverted'
        );

    });

    it('should use Timelock Controller to return ownership of IporAssetConfiguration smart contract', async () => {
        //given
        let iporConfigurationOriginOwner = admin;
        await iporConfiguration.transferOwnership(timelockController.address);

        let fnParamAddress = userThree;

        let calldata = await iporConfiguration.contract.methods.transferOwnership(iporConfigurationOriginOwner).encodeABI();

        //First try cannot be done, because ownership is transfered to Timelock Controller
        await testUtils.assertError(
            iporConfiguration.setMilton(fnParamAddress, {from: iporConfigurationOriginOwner}),
            'Ownable: caller is not the owner'
        );

        //when
        await timelockController.schedule(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporConfiguration.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            {from: userTwo}
        );

        await iporConfiguration.setMilton(fnParamAddress, {from: iporConfigurationOriginOwner});

        //then
        let actualMiltonAddress = await iporConfiguration.getMilton();

        assert(fnParamAddress === actualMiltonAddress,
            `Incorrect Milton address actual: ${actualMiltonAddress}, expected: ${fnParamAddress}`)

    });
});
