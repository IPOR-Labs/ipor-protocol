const testUtils = require("./TestUtils.js");
const {time, BN} = require("@openzeppelin/test-helpers");
const {ZERO} = require("./TestUtils");
const MiltonConfiguration = artifacts.require('MiltonConfiguration');
const TestMilton = artifacts.require('TestMilton');
const MiltonStorage = artifacts.require('MiltonStorage');
const TestWarren = artifacts.require('TestWarren');
const WarrenStorage = artifacts.require('WarrenStorage');
const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const DerivativeLogic = artifacts.require('DerivativeLogic');
const SoapIndicatorLogic = artifacts.require('SoapIndicatorLogic');
const TotalSoapIndicatorLogic = artifacts.require('TotalSoapIndicatorLogic');
const IporAddressesManager = artifacts.require('IporAddressesManager');

contract('MiltonStorage', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress, _] = accounts;

    let milton = null;
    let miltonStorage = null;
    let derivativeLogic = null;
    let soapIndicatorLogic = null;
    let totalSoapIndicatorLogic = null;
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let warren = null;
    let warrenStorage = null;
    let miltonConfiguration = null;
    let iporAddressesManager = null;

    before(async () => {
        derivativeLogic = await DerivativeLogic.deployed();
        soapIndicatorLogic = await SoapIndicatorLogic.deployed();
        totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deployed();
        miltonConfiguration = await MiltonConfiguration.deployed();
        iporAddressesManager = await IporAddressesManager.deployed();

        //10 000 000 000 000 USD
        tokenUsdt = await UsdtMockedToken.new(testUtils.TOTAL_SUPPLY_6_DECIMALS, 6);
        //10 000 000 000 000 USD
        //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
        tokenUsdc = await UsdcMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        //10 000 000 000 000 USD
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);

        warrenStorage = await WarrenStorage.new(1);
        warren = await TestWarren.new(warrenStorage.address);
        milton = await TestMilton.new();


        for (let i = 1; i < accounts.length - 2; i++) {
            //AMM has rights to spend money on behalf of user
            await tokenUsdt.approve(milton.address, testUtils.TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
            //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
            await tokenUsdc.approve(milton.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
            await tokenDai.approve(milton.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
        }

        await iporAddressesManager.setAddress("WARREN", warren.address);
        await iporAddressesManager.setAddress("MILTON_CONFIGURATION", await miltonConfiguration.address);
        await iporAddressesManager.setAddress("MILTON", milton.address);

        await iporAddressesManager.setAddress("USDT", tokenUsdt.address);
        await iporAddressesManager.setAddress("USDC", tokenUsdc.address);
        await iporAddressesManager.setAddress("DAI", tokenDai.address);

        await milton.initialize(iporAddressesManager.address);

    });

    beforeEach(async () => {
        miltonStorage = await MiltonStorage.new();
        await warrenStorage.addUpdater(userOne);
        await warrenStorage.addUpdater(warren.address);
        await iporAddressesManager.setAddress("MILTON_STORAGE", miltonStorage.address);
        await miltonStorage.initialize(iporAddressesManager.address);

    });

    it('should update Milton Storage when open position, caller has rights to update', async () => {

        //given
        await setupTokenDaiInitialValues();
        await iporAddressesManager.setAddress("MILTON", miltonStorageAddress);

        //when
        miltonStorage.updateStorageWhenOpenPosition(await preprareDerivativeStructSimpleCase1(), {from: miltonStorageAddress});
        //then
        assert(true);//no exception this line is achieved

    });

    it('should NOT update Milton Storage when open position, caller dont have rights to update', async () => {
        await testUtils.assertError(
            //when
            miltonStorage.updateStorageWhenOpenPosition(await preprareDerivativeStructSimpleCase1(), {from: userThree}),
            //then
            'IPOR_1'
        );
    });

    it('should update Milton Storage when close position, caller has rights to update', async () => {
        //given
        await setupTokenDaiInitialValues();
        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await warren.test_updateIndex(derivativeParams.asset, testUtils.MILTON_5_PERCENTAGE, derivativeParams.openTimestamp, {from: userOne});
        await iporAddressesManager.setAddress("MILTON", milton.address);
        await openPositionFunc(derivativeParams);
        let derivativeItem = await miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await iporAddressesManager.setAddress("MILTON", miltonStorageAddress);

        //when
        miltonStorage.updateStorageWhenClosePosition(
            userTwo, derivativeItem, BigInt("10000000000000000000"), closePositionTimestamp, {from: miltonStorageAddress});
        //then
        assert(true);//no exception this line is achieved
    });

    it('should NOT update Milton Storage when close position, caller dont have rights to update', async () => {
        // given
        await setupTokenDaiInitialValues();
        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await warren.test_updateIndex(derivativeParams.asset, testUtils.MILTON_5_PERCENTAGE, derivativeParams.openTimestamp, {from: userOne});
        await iporAddressesManager.setAddress("MILTON", milton.address);
        await openPositionFunc(derivativeParams);
        let derivativeItem = await miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await iporAddressesManager.setAddress("MILTON", miltonStorageAddress);

        //when
        await testUtils.assertError(
            miltonStorage.updateStorageWhenClosePosition(
                userTwo, derivativeItem, BigInt("10000000000000000000"), closePositionTimestamp, {from: userThree}),
            //then
            'IPOR_1'
        );

    });

    const openPositionFunc = async (params) => {
        await milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.leverage,
            params.direction, {from: params.from});
    }

    const setupTokenUsdtInitialValues = async () => {
        await tokenUsdt.setupInitialAmount(await milton.address, ZERO);
        await tokenUsdt.setupInitialAmount(admin, testUtils.USER_SUPPLY_6_DECIMALS);
        await tokenUsdt.setupInitialAmount(userOne, testUtils.USER_SUPPLY_6_DECIMALS);
        await tokenUsdt.setupInitialAmount(userTwo, testUtils.USER_SUPPLY_6_DECIMALS);
        await tokenUsdt.setupInitialAmount(userThree, testUtils.USER_SUPPLY_6_DECIMALS);
        await tokenUsdt.setupInitialAmount(liquidityProvider, testUtils.USER_SUPPLY_6_DECIMALS);
    }
    const setupTokenUsdcInitialValues = async () => {
        await tokenUsdc.setupInitialAmount(await milton.address, ZERO);
        await tokenUsdc.setupInitialAmount(admin, testUtils.USER_SUPPLY_18_DECIMALS);
        await tokenUsdc.setupInitialAmount(userOne, testUtils.USER_SUPPLY_18_DECIMALS);
        await tokenUsdc.setupInitialAmount(userTwo, testUtils.USER_SUPPLY_18_DECIMALS);
        await tokenUsdc.setupInitialAmount(userThree, testUtils.USER_SUPPLY_18_DECIMALS);
        await tokenUsdc.setupInitialAmount(liquidityProvider, testUtils.USER_SUPPLY_18_DECIMALS);
    }

    const setupTokenDaiInitialValues = async () => {
        await tokenDai.setupInitialAmount(await milton.address, ZERO);
        await tokenDai.setupInitialAmount(admin, testUtils.USER_SUPPLY_18_DECIMALS);
        await tokenDai.setupInitialAmount(userOne, testUtils.USER_SUPPLY_18_DECIMALS);
        await tokenDai.setupInitialAmount(userTwo, testUtils.USER_SUPPLY_18_DECIMALS);
        await tokenDai.setupInitialAmount(userThree, testUtils.USER_SUPPLY_18_DECIMALS);
        await tokenDai.setupInitialAmount(liquidityProvider, testUtils.USER_SUPPLY_18_DECIMALS);
    }
    const prepareDerivativeItemStructSimpleCase1 = async () => {
        let item = await preprareDerivativeStructSimpleCase1();
        return {
            item: item,
            idsIndex: 111,
            userDerivativeIdsIndex: 222
        }
    };

    const preprareDerivativeStructSimpleCase1 = async () => {
        let openingTimestamp = Math.floor(Date.now() / 1000);
        let closePositionTimestamp = openingTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        return {
            id: 1,
            state: 0,
            buyer: userTwo,
            asset: "DAI",
            direction: 0,
            depositAmount: BigInt("1000000000000000000000"),
            fee: {
                liquidationDepositAmount: BigInt("20000000000000000000"),
                openingAmount: 123,
                iporPublicationAmount: 123,
                spreadPercentage: 123
            },
            leverage: 10,
            notionalAmount: 123,
            startingTimestamp: openingTimestamp,
            endingTimestamp: closePositionTimestamp,
            indicator: {
                iporIndexValue: 123,
                ibtPrice: 123,
                ibtQuantity: 123,
                fixedInterestRate: 234
            }
        };
    }
});