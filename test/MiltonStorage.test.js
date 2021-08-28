const testUtils = require("./TestUtils.js");
const {time, BN} = require("@openzeppelin/test-helpers");
const {ZERO} = require("./TestUtils");
const MiltonConfiguration = artifacts.require('MiltonConfiguration');
const TestMiltonV1Proxy = artifacts.require('TestMiltonV1Proxy');
const MiltonV1Storage = artifacts.require('MiltonV1Storage');
const TestWarrenProxy = artifacts.require('TestWarrenProxy');
const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const DerivativeLogic = artifacts.require('DerivativeLogic');
const SoapIndicatorLogic = artifacts.require('SoapIndicatorLogic');
const TotalSoapIndicatorLogic = artifacts.require('TotalSoapIndicatorLogic');
const MiltonAddressesManager = artifacts.require('MiltonAddressesManager');

contract('MiltonStorage', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress, _] = accounts;

    //10 000 000 000 000 USD
    let totalSupply6Decimals = '1000000000000000000000';
    //10 000 000 000 000 USD
    let totalSupply18Decimals = '10000000000000000000000000000000000';

    //10 000 000 USD
    let userSupply6Decimals = '10000000000000';

    //10 000 000 USD
    let userSupply18Decimals = '10000000000000000000000000';

    let milton = null;
    let miltonStorage = null;
    let derivativeLogic = null;
    let soapIndicatorLogic = null;
    let totalSoapIndicatorLogic = null;
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let warren = null;
    let miltonConfiguration = null;
    let miltonAddressesManager = null;

    before(async () => {
        derivativeLogic = await DerivativeLogic.deployed();
        soapIndicatorLogic = await SoapIndicatorLogic.deployed();
        totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deployed();
        miltonConfiguration = await MiltonConfiguration.deployed();
        miltonAddressesManager = await MiltonAddressesManager.deployed();

        //10 000 000 000 000 USD
        tokenUsdt = await UsdtMockedToken.new(totalSupply6Decimals, 6);
        //10 000 000 000 000 USD
        //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
        tokenUsdc = await UsdcMockedToken.new(totalSupply18Decimals, 18);
        //10 000 000 000 000 USD
        tokenDai = await DaiMockedToken.new(totalSupply18Decimals, 18);

        warren = await TestWarrenProxy.new();
        milton = await TestMiltonV1Proxy.new();


        for (let i = 1; i < accounts.length - 2; i++) {
            //AMM has rights to spend money on behalf of user
            await tokenUsdt.approve(milton.address, totalSupply6Decimals, {from: accounts[i]});
            //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
            await tokenUsdc.approve(milton.address, totalSupply18Decimals, {from: accounts[i]});
            await tokenDai.approve(milton.address, totalSupply18Decimals, {from: accounts[i]});
        }

        await miltonAddressesManager.setAddress("WARREN", warren.address);
        await miltonAddressesManager.setAddress("MILTON_CONFIGURATION", await miltonConfiguration.address);
        await miltonAddressesManager.setAddress("MILTON", milton.address);

        await miltonAddressesManager.setAddress("USDT", tokenUsdt.address);
        await miltonAddressesManager.setAddress("USDC", tokenUsdc.address);
        await miltonAddressesManager.setAddress("DAI", tokenDai.address);

        await milton.initialize(miltonAddressesManager.address);

    });

    beforeEach(async () => {

        await warren.setupInitialValues(userOne);
        miltonStorage = await MiltonV1Storage.new();
        await miltonAddressesManager.setAddress("MILTON_STORAGE", miltonStorage.address);
        await miltonStorage.initialize(miltonAddressesManager.address);

    });

    it('should update Milton Storage when open position, caller has rights to update', async () => {

        //given
        await setupTokenDaiInitialValues();
        await miltonAddressesManager.setAddress("MILTON", miltonStorageAddress);

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
        await miltonAddressesManager.setAddress("MILTON", milton.address);
        await openPositionFunc(derivativeParams);
        let derivativeItem = await miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await miltonAddressesManager.setAddress("MILTON", miltonStorageAddress);

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
        await miltonAddressesManager.setAddress("MILTON", milton.address);
        await openPositionFunc(derivativeParams);
        let derivativeItem = await miltonStorage.getDerivativeItem(1);
        let closePositionTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await miltonAddressesManager.setAddress("MILTON", miltonStorageAddress);

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
        await tokenUsdt.setupInitialAmount(admin, userSupply6Decimals);
        await tokenUsdt.setupInitialAmount(userOne, userSupply6Decimals);
        await tokenUsdt.setupInitialAmount(userTwo, userSupply6Decimals);
        await tokenUsdt.setupInitialAmount(userThree, userSupply6Decimals);
        await tokenUsdt.setupInitialAmount(liquidityProvider, userSupply6Decimals);
    }
    const setupTokenUsdcInitialValues = async () => {
        await tokenUsdc.setupInitialAmount(await milton.address, ZERO);
        await tokenUsdc.setupInitialAmount(admin, userSupply18Decimals);
        await tokenUsdc.setupInitialAmount(userOne, userSupply18Decimals);
        await tokenUsdc.setupInitialAmount(userTwo, userSupply18Decimals);
        await tokenUsdc.setupInitialAmount(userThree, userSupply18Decimals);
        await tokenUsdc.setupInitialAmount(liquidityProvider, userSupply18Decimals);
    }

    const setupTokenDaiInitialValues = async () => {
        await tokenDai.setupInitialAmount(await milton.address, ZERO);
        await tokenDai.setupInitialAmount(admin, userSupply18Decimals);
        await tokenDai.setupInitialAmount(userOne, userSupply18Decimals);
        await tokenDai.setupInitialAmount(userTwo, userSupply18Decimals);
        await tokenDai.setupInitialAmount(userThree, userSupply18Decimals);
        await tokenDai.setupInitialAmount(liquidityProvider, userSupply18Decimals);
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