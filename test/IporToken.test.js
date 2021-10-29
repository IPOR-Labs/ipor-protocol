const keccak256 = require('keccak256')
const testUtils = require("./TestUtils.js");
const {time, BN} = require("@openzeppelin/test-helpers");
const {ZERO} = require("./TestUtils");
const IporConfiguration = artifacts.require('IporConfiguration');
const TestMilton = artifacts.require('TestMilton');
const TestJoseph = artifacts.require('TestJoseph');
const MiltonStorage = artifacts.require('MiltonStorage');
const TestWarren = artifacts.require('TestWarren');
const WarrenStorage = artifacts.require('WarrenStorage');
const IporToken = artifacts.require('IporToken');
const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const DerivativeLogic = artifacts.require('DerivativeLogic');
const SoapIndicatorLogic = artifacts.require('SoapIndicatorLogic');
const TotalSoapIndicatorLogic = artifacts.require('TotalSoapIndicatorLogic');
const IporAddressesManager = artifacts.require('IporAddressesManager');
const MiltonDevToolDataProvider = artifacts.require('MiltonDevToolDataProvider');

contract('IporToken', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let milton = null;
    let miltonStorage = null;
    let derivativeLogic = null;
    let soapIndicatorLogic = null;
    let totalSoapIndicatorLogic = null;
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporTokenUsdt = null;
    let iporTokenUsdc = null;
    let iporTokenDai = null;
    let warren = null;
    let warrenStorage = null;
    let iporConfigurationUsdc = null;
    let iporConfigurationUsdt = null;
    let iporConfigurationDai = null;
    let iporAddressesManager = null;
    let miltonDevToolDataProvider = null;
    let joseph = null;

    before(async () => {
        derivativeLogic = await DerivativeLogic.deployed();
        soapIndicatorLogic = await SoapIndicatorLogic.deployed();
        totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deployed();
        iporAddressesManager = await IporAddressesManager.deployed();
        miltonDevToolDataProvider = await MiltonDevToolDataProvider.deployed();
        joseph = await TestJoseph.new();

        tokenUsdt = await UsdtMockedToken.new(testUtils.TOTAL_SUPPLY_6_DECIMALS, 6);
        tokenUsdc = await UsdcMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        iporConfigurationUsdt = await IporConfiguration.new(tokenUsdt.address);
        iporConfigurationUsdc = await IporConfiguration.new(tokenUsdc.address);
        iporConfigurationDai = await IporConfiguration.new(tokenDai.address);
        await iporAddressesManager.addAsset(tokenUsdt.address);
        await iporAddressesManager.addAsset(tokenUsdc.address);
        await iporAddressesManager.addAsset(tokenDai.address);
        await iporAddressesManager.setIporConfiguration(tokenUsdt.address, await iporConfigurationUsdt.address);
        await iporAddressesManager.setIporConfiguration(tokenUsdc.address, await iporConfigurationUsdc.address);
        await iporAddressesManager.setIporConfiguration(tokenDai.address, await iporConfigurationDai.address);

        iporTokenUsdt = await IporToken.new(tokenUsdt.address, "IPOR USDT", "ipUSDT");
        iporTokenUsdc = await IporToken.new(tokenUsdc.address, "IPOR USDC", "ipUSDC");
        iporTokenDai = await IporToken.new(tokenDai.address, "IPOR DAI", "ipDAI");
        iporTokenUsdt.initialize(iporAddressesManager.address);
        iporTokenUsdc.initialize(iporAddressesManager.address);
        iporTokenDai.initialize(iporAddressesManager.address);

        await iporAddressesManager.setIporToken(tokenUsdt.address, iporTokenUsdt.address);
        await iporAddressesManager.setIporToken(tokenUsdc.address, iporTokenUsdc.address);
        await iporAddressesManager.setIporToken(tokenDai.address, iporTokenDai.address);

        milton = await TestMilton.new();

        for (let i = 1; i < accounts.length - 2; i++) {
            //Liquidity Pool has rights to spend money on behalf of user accounts[i]
            await tokenUsdt.approve(joseph.address, testUtils.TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
            await tokenUsdc.approve(joseph.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
            await tokenDai.approve(joseph.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});

            //Milton has rights to spend money on behalf of user accounts[i]
            await tokenUsdt.approve(milton.address, testUtils.TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
            await tokenUsdc.approve(milton.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
            await tokenDai.approve(milton.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
        }

        await iporAddressesManager.setAddress(keccak256("JOSEPH"), await joseph.address);
        await iporAddressesManager.setAddress(keccak256("MILTON"), milton.address);

        await milton.initialize(iporAddressesManager.address);
        await joseph.initialize(iporAddressesManager.address);
        await milton.authorizeJoseph(tokenDai.address);

    });

    beforeEach(async () => {
        miltonStorage = await MiltonStorage.new();
        await iporAddressesManager.setAddress(keccak256("MILTON_STORAGE"), miltonStorage.address);

        warrenStorage = await WarrenStorage.new();

        warren = await TestWarren.new(warrenStorage.address);
        await iporAddressesManager.setAddress(keccak256("WARREN"), warren.address);

        await warrenStorage.addUpdater(userOne);
        await warrenStorage.addUpdater(warren.address);

        await miltonStorage.initialize(iporAddressesManager.address);

        await miltonStorage.addAsset(tokenDai.address);
        await miltonStorage.addAsset(tokenUsdc.address);
        await miltonStorage.addAsset(tokenUsdt.address);

        iporConfigurationDAI = await IporConfiguration.new(tokenDai.address);

    });


    it('should NOT mint IPOR Token if not a Liquidity Pool', async () => {

        //when
        await testUtils.assertError(
            //when
            iporTokenDai.mint(userOne, testUtils.USD_10_000_18DEC, {from: userTwo}),
            //then
            'IPOR_46'
        );

    });

    it('should NOT burn IPOR Token if not a Liquidity Pool', async () => {
        //when
        await testUtils.assertError(
            //when
            iporTokenDai.burn(userOne, userTwo, testUtils.USD_10_000_18DEC, {from: userTwo}),
            //then
            'IPOR_46'
        );
    });
});
