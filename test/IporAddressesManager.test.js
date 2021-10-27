const testUtils = require("./TestUtils.js");
const {ZERO_BYTES32} = require("@openzeppelin/test-helpers/src/constants");
const {time} = require("@openzeppelin/test-helpers");
const keccak256 = require("keccak256");

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
    let iporConfiguration = null;
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
        await iporAddressesManager.addAsset(tokenUsdt.address);
        await iporAddressesManager.addAsset(tokenUsdc.address);
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
            `Incorrect  Charlie Treasurer address for ${asset}, actual: ${actualCharlieTreasurerDaiAddress}, expected: ${charlieTreasurersDaiAddress}`)
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
            `Incorrect  Trasure Treasurer address for ${asset}, actual: ${actualTreasureTreasurerDaiAddress}, expected: ${treasureTreasurerDaiAddress}`)
    });

    it('should use Timelock Controller - simple case 1', async () => {
        //given
        await iporAddressesManager.transferOwnership(timelockController.address);

        let fnParamId = keccak256("MILTON");
        let fnParamAddress = userThree;

        let calldata = prepareCallData(fnParamId, fnParamAddress);

        //when
        await timelockController.schedule(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            {from: userTwo}
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
        let calldata = prepareCallData(fnParamId, fnParamAddress);

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
                {from: userThree}
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
        let calldata = prepareCallData(fnParamId, fnParamAddress);

        await timelockController.schedule(
            iporAddressesManager.address,
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
                iporAddressesManager.address,
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

    it('should FAIL when used Timelock Controller, because Timelock is not an Owner of IporConfiguration smart contract', async () => {

        //given
        let fnParamId = keccak256("MILTON");
        let fnParamAddress = userThree;
        let calldata = prepareCallData(fnParamId, fnParamAddress);

        await timelockController.schedule(
            iporAddressesManager.address,
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
                iporAddressesManager.address,
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

    it('should use Timelock Controller to return ownership of IporConfiguration smart contract', async () => {
        //given
        let iporAddressesManagerOriginOwner = admin;
        await iporAddressesManager.transferOwnership(timelockController.address);

        let fnParamId = keccak256("MILTON");
        let fnParamAddress = userThree;

        let fnTransferOwnershipSignature = web3.utils.sha3("transferOwnership(address)").substr(0, 10);
        let fnTransferOwnershipParam = testUtils.pad32Bytes(iporAddressesManagerOriginOwner.substr(2))
        let calldata = fnTransferOwnershipSignature + fnTransferOwnershipParam;

        //First try cannot be done, because ownership is transfered to Timelock Controller
        await testUtils.assertError(
            iporAddressesManager.setAddress(fnParamId, fnParamAddress, {from: iporAddressesManagerOriginOwner}),
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
            {from: userOne}
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporAddressesManager.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            {from: userTwo}
        );

        await iporAddressesManager.setAddress(fnParamId, fnParamAddress, {from: iporAddressesManagerOriginOwner});

        //then
        let actualMiltonAddress = await iporAddressesManager.getAddress(fnParamId);

        assert(fnParamAddress === actualMiltonAddress,
            `Incorrect Milton address actual: ${actualMiltonAddress}, expected: ${fnParamAddress}`)

    });

    function prepareCallData(id, address) {
        let fnSignature = web3.utils.sha3("setAddress(bytes32,address)").substr(0, 10);
        let fnParamId = id.toString("hex");
        let fnParamIdPad = testUtils.pad32Bytes(fnParamId);
        let fnParamAddressPad = testUtils.pad32Bytes(address.substr(2));
        let calldata = fnSignature + fnParamIdPad + fnParamAddressPad;
        return calldata;
    }

});
