const testUtils = require("./TestUtils.js");
const {time, BN} = require("@openzeppelin/test-helpers");
const {ZERO} = require("./TestUtils");
const MiltonConfiguration = artifacts.require('MiltonConfiguration');
const TestMilton = artifacts.require('TestMilton');
const MiltonStorage = artifacts.require('MiltonStorage');
const TestWarren = artifacts.require('TestWarren');
const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const DerivativeLogic = artifacts.require('DerivativeLogic');
const SoapIndicatorLogic = artifacts.require('SoapIndicatorLogic');
const TotalSoapIndicatorLogic = artifacts.require('TotalSoapIndicatorLogic');
const MiltonAddressesManager = artifacts.require('MiltonAddressesManager');

contract('MiltonSoap', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

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
        milton = await TestMilton.new();

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
        miltonStorage = await MiltonStorage.new();
        await miltonAddressesManager.setAddress("MILTON_STORAGE", miltonStorage.address);
        await miltonStorage.initialize(miltonAddressesManager.address);

    });

    it('should calculate soap, no derivatives, soap equal 0', async () => {
        //given
        const params = {
            asset: "DAI",
            calculateTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        let expectedSoap = testUtils.ZERO;

        //when
        let actualSoapStruct = await calculateSoap(params)
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then

        assert(expectedSoap === actualSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${expectedSoap}`)
    });

    it('should calculate soap, DAI, pay fixed, add position, calculate now', async () => {

        //given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_5_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = testUtils.ZERO;

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);

    });


    it('should calculate soap, DAI, pay fixed, add position, calculate after 25 days', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = BigInt("-67604794520547965486");

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI, rec fixed, add position, calculate now', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 1;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = testUtils.ZERO;

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: derivativeParams.openTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI, rec fixed, add position, calculate after 25 days', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 1;
        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = BigInt("-67604794520547924923");

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI, pay fixed, add and remove position', async () => {
        // given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let endTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        let expectedSoap = testUtils.ZERO;

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: endTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI, rec fixed, add and remove position', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 1;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = testUtils.ZERO;
        let endTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await milton.provideLiquidity(derivativeParams.asset, testUtils.MILTON_10_000_USD, {from: liquidityProvider})

        //when
        await milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});


        const soapParams = {
            asset: "DAI",
            calculateTimestamp: derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed', async () => {
        //given
        await setupTokenDaiInitialValues();
        let firstDerivativeDirection = 0;
        let secondDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: firstDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const secondDerivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: secondDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await warren.test_updateIndex(firstDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(firstDerivativeParams);
        await openPositionFunc(secondDerivativeParams);

        let expectedSoap = BigInt("-135209589041095890410");

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, USDC add pay fixed', async () => {
        //given
        await setupTokenDaiInitialValues();
        await setupTokenUsdcInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeDAIParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const derivativeUSDCParams = {
            asset: "USDC",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeDAIParams.asset, iporValueBeforOpenPosition, derivativeDAIParams.openTimestamp, {from: userOne});
        await warren.test_updateIndex(derivativeUSDCParams.asset, iporValueBeforOpenPosition, derivativeUSDCParams.openTimestamp, {from: userOne});

        //when
        await openPositionFunc(derivativeDAIParams);
        await openPositionFunc(derivativeUSDCParams);

        //then
        let expectedDAISoap = BigInt("-67604794520547965486");
        //TODO: poprawic gdy zmiana na 6 miejsc po przecinku (zmiany w całym kodzie)
        let expectedUSDCSoap = BigInt("-67604794520547965486");

        const soapDAIParams = {
            asset: "DAI",
            calculateTimestamp: derivativeDAIParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedDAISoap,
            from: userTwo
        }
        await assertSoap(soapDAIParams);

        const soapUSDCParams = {
            asset: "USDC",
            calculateTimestamp: derivativeUSDCParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedUSDCSoap,
            from: userTwo
        }
        await assertSoap(soapUSDCParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed, close rec fixed position', async () => {
        //given
        await setupTokenDaiInitialValues();
        let payFixDerivativeDirection = 0;
        let recFixDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: payFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: recFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await warren.test_updateIndex(payFixDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(payFixDerivativeParams);
        await openPositionFunc(recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await milton.test_closePosition(2, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoap = BigInt("-67604794520547965486");

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed, remove pay fixed position after 25 days', async () => {
        //given
        await setupTokenDaiInitialValues();
        let payFixDerivativeDirection = 0;
        let recFixDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: payFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: recFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await warren.test_updateIndex(payFixDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(payFixDerivativeParams);
        await openPositionFunc(recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoap = BigInt("-67604794520547924923");

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, USDC add rec fixed, remove rec fixed position after 25 days', async () => {
        //given
        await setupTokenDaiInitialValues();
        await setupTokenUsdcInitialValues();
        let payFixDerivativeDAIDirection = 0;
        let recFixDerivativeUSDCDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeDAIParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: payFixDerivativeDAIDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeUSDCParams = {
            asset: "USDC",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: recFixDerivativeUSDCDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await warren.test_updateIndex(payFixDerivativeDAIParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await warren.test_updateIndex(recFixDerivativeUSDCParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});

        await openPositionFunc(payFixDerivativeDAIParams);
        await openPositionFunc(recFixDerivativeUSDCParams);

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await milton.provideLiquidity(recFixDerivativeUSDCParams.asset, testUtils.MILTON_10_000_USD, {from: liquidityProvider})

        let endTimestamp = recFixDerivativeUSDCParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await milton.test_closePosition(2, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoap = BigInt("-67604794520547965486");

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI add pay fixed, change ibtPrice, wait 25 days and then calculate soap', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let iporValueAfterOpenPosition = testUtils.MILTON_120_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);
        await warren.test_updateIndex(derivativeParams.asset, iporValueAfterOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await warren.test_updateIndex(derivativeParams.asset, testUtils.MILTON_6_PERCENTAGE, calculationTimestamp, {from: userOne});

        let expectedSoap = BigInt("7842156164383561622202");

        //when
        //then
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: calculationTimestamp,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI add pay fixed, change ibtPrice, calculate soap after 28 days and after 50 days and compare', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let iporValueAfterOpenPosition = testUtils.MILTON_120_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp25days = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp28days = derivativeParams.openTimestamp + testUtils.PERIOD_28_DAYS_IN_SECONDS;
        let calculationTimestamp50days = derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS;

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);
        await warren.test_updateIndex(derivativeParams.asset, iporValueAfterOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await warren.test_updateIndex(derivativeParams.asset, testUtils.MILTON_6_PERCENTAGE, calculationTimestamp25days, {from: userOne});

        let expectedSoap28Days = BigInt("7858381315068493143924");
        let expectedSoap50Days = BigInt("7977365753424657570753");

        //when
        //then
        const soapParams28days = {
            asset: "DAI",
            calculateTimestamp: calculationTimestamp28days,
            expectedSoap: expectedSoap28Days,
            from: userTwo
        }
        await assertSoap(soapParams28days);

        const soapParams50days = {
            asset: "DAI",
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap50Days,
            from: userTwo
        }
        await assertSoap(soapParams50days);
    });


    it('should calculate soap, DAI add pay fixed, wait 25 days, DAI add pay fixed, wait 25 days and then calculate soap', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        const derivativeParams25days = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        let calculationTimestamp50days = derivativeParams25days.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);
        await openPositionFunc(derivativeParams25days);

        //then
        let expectedSoap = BigInt("-203230270882686228234");

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);

    });

    it('should calculate soap, DAI add pay fixed, wait 25 days, update IPOR and DAI add pay fixed, wait 25 days update IPOR and then calculate soap', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        const derivativeParams25days = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        let calculationTimestamp50days = derivativeParams25days.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;

        //when
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParams25days.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams25days);
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, calculationTimestamp50days, {from: userOne});

        //then
        let expectedSoap = BigInt("-203230270882686228234");

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);

    });


    it('should calculate EXACTLY the same SOAP with and without update IPOR Index with the same indexValue, DAI add pay fixed, 25 and 50 days period', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp25days = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp50days = derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS;
        let soapBeforeUpdateIndex = null;

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: calculationTimestamp50days,
            from: userTwo
        }

        //when
        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let soapBeforeUpdateIndexStruct = await calculateSoap(soapParams);
        soapBeforeUpdateIndex = BigInt(soapBeforeUpdateIndexStruct.soap);

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, calculationTimestamp25days, {from: userOne});
        let soapUpdateIndexAfter25DaysStruct = await calculateSoap(soapParams);
        let soapUpdateIndexAfter25Days = BigInt(soapUpdateIndexAfter25DaysStruct.soap);

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, calculationTimestamp50days, {from: userOne});
        let soapUpdateIndexAfter50DaysStruct = await calculateSoap(soapParams);
        let soapUpdateIndexAfter50Days = BigInt(soapUpdateIndexAfter50DaysStruct.soap);


        //then
        let expectedSoap = BigInt("-135209589041095930973");

        assert(expectedSoap === soapBeforeUpdateIndex,
            `Incorrect SOAP before update index for asset ${soapParams.asset} actual: ${soapBeforeUpdateIndex}, expected: ${expectedSoap}`);
        assert(expectedSoap === soapUpdateIndexAfter25Days,
            `Incorrect SOAP update index after 25 days for asset ${soapParams.asset} actual: ${soapUpdateIndexAfter25Days}, expected: ${expectedSoap}`);
        assert(expectedSoap === soapUpdateIndexAfter50Days,
            `Incorrect SOAP update index after 50 days for asset ${soapParams.asset} actual: ${soapUpdateIndexAfter50Days}, expected: ${expectedSoap}`);
    });


    it('should calculate NEGATIVE SOAP, DAI add pay fixed, wait 25 days, update ibtPrice after derivative opened, soap should be negative right after opened position and updated ibtPrice', async () => {
        //given
        await setupTokenDaiInitialValues();
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let iporValueAfterOpenPosition = testUtils.MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        let firstUpdateIndexTimestamp = openTimestamp;
        let secondUpdateIndexTimestamp = firstUpdateIndexTimestamp + testUtils.PERIOD_1_DAY_IN_SECONDS;

        const derivativeParamsFirst = {
            asset: "DAI",
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: secondUpdateIndexTimestamp,
            from: openerUserAddress
        }
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, firstUpdateIndexTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        //when
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueAfterOpenPosition, secondUpdateIndexTimestamp, {from: userOne});

        let rightAfterOpenedPositionTimestamp = secondUpdateIndexTimestamp + 100;

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: rightAfterOpenedPositionTimestamp,
            expectedSoap: 0,
            from: userTwo
        }
        let actualSoapStruct = await calculateSoap(soapParams);
        let actualSoap = BigInt(actualSoapStruct.soap);


        //then
        assert(actualSoap < 0, `SOAP is positive but should be negative, actual: ${actualSoap}`);

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

    const assertSoap = async (params) => {
        let actualSoapStruct = await calculateSoap(params);
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then
        assert(params.expectedSoap === actualSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`)
    }

    const calculateSoap = async (params) => {
        return await milton.test_calculateSoap.call(params.asset, params.calculateTimestamp, {from: params.from});
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

});
