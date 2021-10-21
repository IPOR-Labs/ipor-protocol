const testUtils = require("./TestUtils.js");
const {time, BN} = require("@openzeppelin/test-helpers");
const {ZERO} = require("./TestUtils");
const TestUtils = require("./TestUtils");
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
const Joseph = artifacts.require('Joseph');

contract('Joseph', (accounts) => {

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
    let iporConfiguration = null;
    let iporAddressesManager = null;
    let miltonDevToolDataProvider = null;
    let joseph = null;

    before(async () => {
        derivativeLogic = await DerivativeLogic.deployed();
        soapIndicatorLogic = await SoapIndicatorLogic.deployed();
        totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deployed();
        iporConfiguration = await IporConfiguration.deployed();
        iporAddressesManager = await IporAddressesManager.deployed();
        miltonDevToolDataProvider = await MiltonDevToolDataProvider.deployed();
        joseph = await TestJoseph.new();

        //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
        tokenUsdt = await UsdtMockedToken.new(testUtils.TOTAL_SUPPLY_6_DECIMALS, 6);
        tokenUsdc = await UsdcMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);


        milton = await TestMilton.new();

        for (let i = 1; i < accounts.length - 2; i++) {
            //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
            //Liquidity Pool has rights to spend money on behalf of user accounts[i]
            await tokenUsdt.approve(joseph.address, testUtils.TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
            await tokenUsdc.approve(joseph.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
            await tokenDai.approve(joseph.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
            //Milton has rights to spend money on behalf of user accounts[i]
            await tokenUsdt.approve(milton.address, testUtils.TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
            await tokenUsdc.approve(milton.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
            await tokenDai.approve(milton.address, testUtils.TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
        }
        await iporAddressesManager.setAddress("IPOR_CONFIGURATION", await iporConfiguration.address);
        await iporAddressesManager.setAddress("JOSEPH", await joseph.address);
        await iporAddressesManager.setAddress("MILTON", milton.address);

        await iporAddressesManager.addAsset(tokenUsdt.address);
        await iporAddressesManager.addAsset(tokenUsdc.address);
        await iporAddressesManager.addAsset(tokenDai.address);

        await milton.initialize(iporAddressesManager.address);
        await joseph.initialize(iporAddressesManager.address);
        await milton.authorizeJoseph(tokenDai.address);
        await milton.authorizeJoseph(tokenUsdc.address);

    });

    beforeEach(async () => {
        miltonStorage = await MiltonStorage.new();
        await iporAddressesManager.setAddress("MILTON_STORAGE", miltonStorage.address);

        warrenStorage = await WarrenStorage.new();

        warren = await TestWarren.new(warrenStorage.address);
        await iporAddressesManager.setAddress("WARREN", warren.address);

        await warrenStorage.addUpdater(userOne);
        await warrenStorage.addUpdater(warren.address);

        await miltonStorage.initialize(iporAddressesManager.address);

        await miltonStorage.addAsset(tokenDai.address);
        await miltonStorage.addAsset(tokenUsdc.address);
        await miltonStorage.addAsset(tokenUsdt.address);

        iporTokenUsdt = await IporToken.new(tokenUsdt.address, 6, "IPOR USDT", "ipUSDT");
        iporTokenUsdt.initialize(iporAddressesManager.address);
        iporTokenUsdc = await IporToken.new(tokenUsdc.address, 18, "IPOR USDC", "ipUSDC");
        iporTokenUsdc.initialize(iporAddressesManager.address);
        iporTokenDai = await IporToken.new(tokenDai.address, 18, "IPOR DAI", "ipDAI");
        iporTokenDai.initialize(iporAddressesManager.address);

        await iporAddressesManager.setIporToken(tokenUsdt.address, iporTokenUsdt.address);
        await iporAddressesManager.setIporToken(tokenUsdc.address, iporTokenUsdc.address);
        await iporAddressesManager.setIporToken(tokenDai.address, iporTokenDai.address);

    });

    it('should provide liquidity and take IPOR token - simple case 1', async () => {
        //given
        await setupTokenDaiInitialValues();
        await setupIporTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        let liquidityAmount = testUtils.MILTON_14_000_USD;

        let expectedLiquidityProviderStableBalance = BigInt("9986000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = testUtils.MILTON_14_000_USD;
        ;

        //when
        await joseph.provideLiquidity(params.asset, liquidityAmount, {from: liquidityProvider})

        //then
        const actualIporTokenBalanceSender = BigInt(await iporTokenDai.balanceOf(liquidityProvider));
        const actualUnderlyingBalanceMilton = BigInt(await tokenDai.balanceOf(milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await tokenDai.balanceOf(liquidityProvider));


        assert(liquidityAmount === actualIporTokenBalanceSender,
            `Incorrect IPOR Token balance on user for asset ${params.asset} actual: ${actualIporTokenBalanceSender}, expected: ${liquidityAmount}`);

        assert(liquidityAmount === actualUnderlyingBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${liquidityAmount}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect DAI balance on user for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);

    });

    it('should redeem IPOR Token - simple case 1', async () => {
        //given
        await setupTokenDaiInitialValues();
        await setupIporTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        let liquidityAmount = testUtils.MILTON_14_000_USD;
        let withdrawAmount = testUtils.MILTON_10_000_USD;
        let expectedIporTokenBalanceSender = BigInt("4000000000000000000000");
        let expectedStableBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderStableBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolBalanceMilton = expectedStableBalanceMilton;
        let actionTimestamp = Math.floor(Date.now() / 1000);
        await joseph.test_provideLiquidity(params.asset, liquidityAmount, actionTimestamp, {from: liquidityProvider})

        //when
        await joseph.test_redeem(params.asset, withdrawAmount, actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: liquidityProvider});

        //then
        const actualIporTokenBalanceSender = BigInt(await iporTokenDai.balanceOf(liquidityProvider));

        const actualUnderlyingBalanceMilton = BigInt(await tokenDai.balanceOf(milton.address));
        const actualLiquidityPoolBalanceMilton = BigInt(await (await miltonStorage.balances(params.asset)).liquidityPool);
        const actualUnderlyingBalanceSender = BigInt(await tokenDai.balanceOf(liquidityProvider));

        assert(expectedIporTokenBalanceSender === actualIporTokenBalanceSender,
            `Incorrect IPOR Token balance on user for asset ${params.asset} actual: ${actualIporTokenBalanceSender}, expected: ${expectedIporTokenBalanceSender}`);

        assert(expectedStableBalanceMilton === actualUnderlyingBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${params.asset} actual: ${actualUnderlyingBalanceMilton}, expected: ${expectedStableBalanceMilton}`);

        assert(expectedLiquidityPoolBalanceMilton === actualLiquidityPoolBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${params.asset} actual: ${actualLiquidityPoolBalanceMilton}, expected: ${expectedLiquidityPoolBalanceMilton}`);

        assert(expectedLiquidityProviderStableBalance === actualUnderlyingBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${params.asset} actual: ${actualUnderlyingBalanceSender}, expected: ${expectedLiquidityProviderStableBalance}`);

    });

    it('should calculate Exchange Rate when Liquidity Pool Balance and Ipor Token Total Supply is zero', async () => {
        //given
        let expectedExchangeRate = BigInt("1000000000000000000");
        //when
        let actualExchangeRate = BigInt(await joseph.calculateExchangeRate.call(tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and Ipor Token Total Supply is NOT zero', async () => {
        //given
        await setupTokenDaiInitialValues();
        let expectedExchangeRate = BigInt("1000000000000000000");
        const params = getStandardDerivativeParams();

        await joseph.provideLiquidity(params.asset, testUtils.MILTON_14_000_USD, {from: liquidityProvider})

        //when
        let actualExchangeRate = BigInt(await joseph.calculateExchangeRate.call(tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is zero and Ipor Token Total Supply is NOT zero', async () => {
        //given
        await setupTokenDaiInitialValues();
        let expectedExchangeRate = BigInt("0");
        const params = getStandardDerivativeParams();

        await joseph.provideLiquidity(params.asset, testUtils.MILTON_10_000_USD, {from: liquidityProvider})

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await iporAddressesManager.setAddress("JOSEPH", userOne);
        await miltonStorage.subtractLiquidity(params.asset, testUtils.MILTON_10_000_USD, {from: userOne});
        await iporAddressesManager.setAddress("JOSEPH", joseph.address);

        //when
        let actualExchangeRate = BigInt(await joseph.calculateExchangeRate.call(tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`);

    });

    it('should calculate Exchange Rate, Exchange Rate greater than 1', async () => {
        //given
        await setupTokenDaiInitialValues();
        let expectedExchangeRate = BigInt("1022727272727272727");
        const params = getStandardDerivativeParams();
        await warren.updateIndex(params.asset, testUtils.MILTON_3_PERCENTAGE, {from: userOne});
        await joseph.provideLiquidity(params.asset, BigInt("40000000000000000000"), {from: liquidityProvider})

        //open position to have something in Liquidity Pool
        await milton.openPosition(
            params.asset, BigInt("40000000000000000000"),
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //when
        let actualExchangeRate = BigInt(await joseph.calculateExchangeRate.call(tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should calculate Exchange Rate when Liquidity Pool Balance is NOT zero and Ipor Token Total Supply is zero', async () => {
        //given
        let amount = BigInt("40000000000000000000");
        await setupTokenDaiInitialValues();
        let expectedExchangeRate = BigInt("1000000000000000000");
        const params = getStandardDerivativeParams();
        await warren.updateIndex(params.asset, testUtils.MILTON_3_PERCENTAGE, {from: userOne});
        let actionTimestamp = Math.floor(Date.now() / 1000);

        await joseph.test_provideLiquidity(params.asset, amount, actionTimestamp, {from: liquidityProvider});


        //open position to have something in Liquidity Pool
        await milton.openPosition(
            params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        await joseph.test_redeem(params.asset, amount, actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: liquidityProvider})

        //when
        let actualExchangeRate = BigInt(await joseph.calculateExchangeRate.call(tokenDai.address));

        //then
        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
            expected: ${expectedExchangeRate}`)
    });

    it('should NOT change Exchange Rate when Liquidity Provider provide liquidity, initial Exchange Rate equal to 1.5', async () => {

        //given
        let amount = BigInt("180000000000000000000");
        await setupTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        await warren.updateIndex(params.asset, testUtils.MILTON_3_PERCENTAGE, {from: userOne});
        await joseph.provideLiquidity(params.asset, amount, {from: liquidityProvider});
        let oldOpeningFeePercentage = await iporConfiguration.getOpeningFeePercentage();
        await iporConfiguration.setOpeningFeePercentage(BigInt("600000000000000000"));

        //open position to have something in Liquidity Pool
        await milton.openPosition(
            params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //after this withdraw initial exchange rate is 1,5
        let expectedExchangeRate = BigInt("1714285714285714286");
        let exchangeRateBeforeProvideLiquidity = BigInt(await joseph.calculateExchangeRate.call(params.asset));
        let expectedIporTokenBalanceForUserThree = BigInt("874999999999999999854");

        // //when
        await joseph.provideLiquidity(params.asset, BigInt("1500000000000000000000"), {from: userThree});

        let actualIporTokenBalanceForUserThree = BigInt(await iporTokenDai.balanceOf.call(userThree));
        let actualExchangeRate = BigInt(await joseph.calculateExchangeRate.call(params.asset));

        //then
        assert(expectedIporTokenBalanceForUserThree === actualIporTokenBalanceForUserThree,
            `Incorrect ipToken Balance for asset ${params.asset} for user ${userThree}, actual:  ${actualIporTokenBalanceForUserThree},
                 expected: ${expectedIporTokenBalanceForUserThree}`)

        assert(expectedExchangeRate === exchangeRateBeforeProvideLiquidity,
            `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
                expected: ${expectedExchangeRate}`)

        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
                expected: ${expectedExchangeRate}`)

        await iporConfiguration.setOpeningFeePercentage(oldOpeningFeePercentage);
    });

    it('should NOT change Exchange Rate when Liquidity Provider provide liquidity and redeem, initial Exchange Rate equal to 1.5', async () => {
        //given
        let amount = BigInt("180000000000000000000");
        await setupTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        await warren.updateIndex(params.asset, testUtils.MILTON_3_PERCENTAGE, {from: userOne});
        await joseph.provideLiquidity(params.asset, amount, {from: liquidityProvider});
        let oldOpeningFeePercentage = await iporConfiguration.getOpeningFeePercentage();
        await iporConfiguration.setOpeningFeePercentage(BigInt("600000000000000000"));

        //open position to have something in Liquidity Pool
        await milton.openPosition(
            params.asset, amount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //after this withdraw initial exchange rate is 1,5
        let expectedExchangeRate = BigInt("1714285714285714286");
        let exchangeRateBeforeProvideLiquidity = BigInt(await joseph.calculateExchangeRate.call(params.asset));
        let expectedIporTokenBalanceForUserThree = BigInt("0");
        let actionTimestamp = Math.floor(Date.now() / 1000);

        //when
        await joseph.test_provideLiquidity(params.asset, BigInt("1500000000000000000000"), actionTimestamp, {from: userThree});
        await joseph.test_redeem(params.asset, BigInt("874999999999999999854"), actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: userThree})

        let actualIporTokenBalanceForUserThree = BigInt(await iporTokenDai.balanceOf.call(userThree));
        let actualExchangeRate = BigInt(await joseph.calculateExchangeRate.call(params.asset));

        //then
        assert(expectedIporTokenBalanceForUserThree === actualIporTokenBalanceForUserThree,
            `Incorrect ipToken Balance for asset ${params.asset} for user ${userThree}, actual:  ${actualIporTokenBalanceForUserThree},
                 expected: ${expectedIporTokenBalanceForUserThree}`)

        assert(expectedExchangeRate === exchangeRateBeforeProvideLiquidity,
            `Incorrect exchange rate before providing liquidity for DAI, actual:  ${exchangeRateBeforeProvideLiquidity},
                expected: ${expectedExchangeRate}`)

        assert(expectedExchangeRate === actualExchangeRate,
            `Incorrect exchange rate after providing liquidity for DAI, actual:  ${actualExchangeRate},
                expected: ${expectedExchangeRate}`)

        await iporConfiguration.setOpeningFeePercentage(oldOpeningFeePercentage);
    });


    it('should NOT redeem Ipor Tokens because of empty Liquidity Pool', async () => {
        //given
        await setupTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        let actionTimestamp = Math.floor(Date.now() / 1000);
        await joseph.test_provideLiquidity(params.asset, params.totalAmount, actionTimestamp, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await iporAddressesManager.setAddress("JOSEPH", userOne);
        await miltonStorage.subtractLiquidity(params.asset, params.totalAmount, {from: userOne});
        await iporAddressesManager.setAddress("JOSEPH", joseph.address);

        //when
        await testUtils.assertError(
            //when
            joseph.test_redeem(params.asset, BigInt("1000000000000000000000"), actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: liquidityProvider}),
            //then
            'IPOR_45'
        );
    });

    it('should NOT provide liquidity because of empty Liquidity Pool', async () => {
        //given
        await setupTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        await joseph.provideLiquidity(params.asset, params.totalAmount, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await iporAddressesManager.setAddress("JOSEPH", userOne);
        await miltonStorage.subtractLiquidity(params.asset, params.totalAmount, {from: userOne});
        await iporAddressesManager.setAddress("JOSEPH", joseph.address);

        //when
        await testUtils.assertError(
            //when
            joseph.provideLiquidity(params.asset, params.totalAmount, {from: liquidityProvider}),
            //then
            'IPOR_45'
        );
    });

    it('should NOT redeem Ipor Tokens because redeem value higher than Liquidity Pool Balance', async () => {
        //given
        await setupTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        let actionTimestamp = Math.floor(Date.now() / 1000);
        await joseph.test_provideLiquidity(params.asset, params.totalAmount, actionTimestamp, {from: liquidityProvider});

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        await iporAddressesManager.setAddress("JOSEPH", userOne);
        await miltonStorage.subtractLiquidity(params.asset, testUtils.MILTON_10_USD, {from: userOne});
        await iporAddressesManager.setAddress("JOSEPH", joseph.address);

        //when
        await testUtils.assertError(
            //when
            joseph.test_redeem(params.asset, params.totalAmount, actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: liquidityProvider}),
            //then
            'IPOR_43'
        );
    });

    it('should NOT redeem Ipor Tokens because after redeem Liquidity Pool will be empty', async () => {
        //given
        await setupTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        let actionTimestamp = Math.floor(Date.now() / 1000);
        await joseph.test_provideLiquidity(params.asset, params.totalAmount, actionTimestamp, {from: liquidityProvider});

        //when
        await testUtils.assertError(
            //when
            joseph.test_redeem(params.asset, params.totalAmount, actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: liquidityProvider}),
            //then
            'IPOR_43'
        );
    });

    it('should NOT redeem Ipor Tokens because cool off period not passed', async () => {
        //given
        await setupTokenDaiInitialValues();
        const params = getStandardDerivativeParams();
        let actionTimestamp = Math.floor(Date.now() / 1000);
        await joseph.test_provideLiquidity(params.asset, params.totalAmount, actionTimestamp, {from: liquidityProvider});

        //when
        await testUtils.assertError(
            //when
            joseph.test_redeem(params.asset, testUtils.MILTON_9063__63_USD, actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS - 1, {from: liquidityProvider}),
            //then
            'IPOR_47'
        );
    });

    it('should NOT redeem Ipor Tokens because after second providing liquidity cool off period not passed', async () => {
        //given
        await setupTokenDaiInitialValues();
        let actionTimestamp = Math.floor(Date.now() / 1000);

        await joseph.test_provideLiquidity(tokenDai.address, testUtils.MILTON_10_000_USD, actionTimestamp, {from: liquidityProvider});
        await joseph.test_provideLiquidity(tokenDai.address, testUtils.MILTON_10_000_USD, actionTimestamp + testUtils.PERIOD_1_DAY_IN_SECONDS, {from: liquidityProvider});

        //when
        await testUtils.assertError(
            //when
            joseph.test_redeem(tokenDai.address, testUtils.MILTON_9063__63_USD, actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: liquidityProvider}),
            //then
            'IPOR_47'
        );
    });

    it('should NOT redeem ipDAI, should redeem ipUSDC, cool off period not passed for ipDAI, cool off period passed for ipUSDC, one user', async () => {
        //given
        await setupTokenDaiInitialValues();
        await setupTokenUsdcInitialValues();

        await setupIporTokenDaiInitialValues();
        await setupIporTokenUsdcInitialValues();

        let liquidityAmount = testUtils.MILTON_14_000_USD;
        let withdrawAmount = testUtils.MILTON_10_000_USD;

        let expectedipDAIBalanceSender = BigInt("14000000000000000000000");
        let expectedDAIBalanceMilton = BigInt("14000000000000000000000");
        let expectedLiquidityProviderDAIBalance = BigInt("9986000000000000000000000");
        let expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        let expectedipUSDCBalanceSender = BigInt("4000000000000000000000");
        let expectedUSDCBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderUSDCBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolUSDCBalanceMilton = expectedUSDCBalanceMilton;

        let actionTimestamp = Math.floor(Date.now() / 1000);

        await joseph.test_provideLiquidity(tokenDai.address, liquidityAmount, actionTimestamp + testUtils.PERIOD_1_DAY_IN_SECONDS, {from: liquidityProvider});
        await joseph.test_provideLiquidity(tokenUsdc.address, liquidityAmount, actionTimestamp, {from: liquidityProvider});

        let redeemTimestamp = actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS;

        //when
        await joseph.test_redeem(tokenUsdc.address, withdrawAmount, redeemTimestamp, {from: liquidityProvider});

        await testUtils.assertError(
            //when
            joseph.test_redeem(tokenDai.address, withdrawAmount, redeemTimestamp, {from: liquidityProvider}),
            //then
            'IPOR_47'
        );

        //then
        const actualIpDAIBalanceSender = BigInt(await iporTokenDai.balanceOf(liquidityProvider));
        const actualDAIBalanceMilton = BigInt(await tokenDai.balanceOf(milton.address));
        const actualLiquidityPoolDAIBalanceMilton = BigInt(await (await miltonStorage.balances(tokenDai.address)).liquidityPool);
        const actualDAIBalanceSender = BigInt(await tokenDai.balanceOf(liquidityProvider));

        assert(expectedipDAIBalanceSender === actualIpDAIBalanceSender,
            `Incorrect IPOR Token DAI balance on user for asset ${tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`);

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);

        assert(expectedLiquidityPoolDAIBalanceMilton === actualLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`);

        assert(expectedLiquidityProviderDAIBalance === actualDAIBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`);

        const actualIpUSDCBalanceSender = BigInt(await iporTokenUsdc.balanceOf(liquidityProvider));
        const actualUSDCBalanceMilton = BigInt(await tokenUsdc.balanceOf(milton.address));

        const actualLiquidityPoolUSDCBalanceMilton = BigInt(await (await miltonStorage.balances(tokenUsdc.address)).liquidityPool);
        const actualUSDCBalanceSender = BigInt(await tokenUsdc.balanceOf(liquidityProvider));

        assert(expectedipUSDCBalanceSender === actualIpUSDCBalanceSender,
            `Incorrect IPOR Token USDC balance on user for asset ${tokenUsdc.address} actual: ${actualIpUSDCBalanceSender}, expected: ${expectedipUSDCBalanceSender}`);

        assert(expectedUSDCBalanceMilton === actualUSDCBalanceMilton,
            `Incorrect USDC balance on Milton for asset ${tokenUsdc.address} actual: ${actualUSDCBalanceMilton}, expected: ${expectedUSDCBalanceMilton}`);

        assert(expectedLiquidityPoolUSDCBalanceMilton === actualLiquidityPoolUSDCBalanceMilton,
            `Incorrect USDC Liquidity Pool Balance on Milton for asset ${tokenUsdc.address} actual: ${actualLiquidityPoolUSDCBalanceMilton}, expected: ${expectedLiquidityPoolUSDCBalanceMilton}`);

        assert(expectedLiquidityProviderUSDCBalance === actualUSDCBalanceSender,
            `Incorrect USDC balance on Liquidity Provider for asset ${tokenUsdc.address} actual: ${actualUSDCBalanceSender}, expected: ${expectedLiquidityProviderUSDCBalance}`);
    });

    it('should redeem ipDAI, should redeem ipUSDC, cool off period passed for ipDAI and for ipUSDC, one user', async () => {
        //given
        await setupTokenDaiInitialValues();
        await setupTokenUsdcInitialValues();

        await setupIporTokenDaiInitialValues();
        await setupIporTokenUsdcInitialValues();

        let liquidityAmount = testUtils.MILTON_14_000_USD;
        let withdrawAmount = testUtils.MILTON_10_000_USD;

        let expectedipDAIBalanceSender = BigInt("4000000000000000000000");
        let expectedDAIBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderDAIBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        let expectedipUSDCBalanceSender = BigInt("4000000000000000000000");
        let expectedUSDCBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderUSDCBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolUSDCBalanceMilton = expectedUSDCBalanceMilton;

        let actionTimestamp = Math.floor(Date.now() / 1000);

        await joseph.test_provideLiquidity(tokenDai.address, liquidityAmount, actionTimestamp, {from: liquidityProvider});
        await joseph.test_provideLiquidity(tokenUsdc.address, liquidityAmount, actionTimestamp, {from: liquidityProvider});

        let redeemTimestamp = actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS;

        //when
        await joseph.test_redeem(tokenUsdc.address, withdrawAmount, redeemTimestamp, {from: liquidityProvider});
        await joseph.test_redeem(tokenDai.address, withdrawAmount, redeemTimestamp, {from: liquidityProvider});

        //then
        const actualIpDAIBalanceSender = BigInt(await iporTokenDai.balanceOf(liquidityProvider));
        const actualDAIBalanceMilton = BigInt(await tokenDai.balanceOf(milton.address));
        const actualLiquidityPoolDAIBalanceMilton = BigInt(await (await miltonStorage.balances(tokenDai.address)).liquidityPool);
        const actualDAIBalanceSender = BigInt(await tokenDai.balanceOf(liquidityProvider));

        assert(expectedipDAIBalanceSender === actualIpDAIBalanceSender,
            `Incorrect IPOR Token DAI balance on user for asset ${tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`);

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);

        assert(expectedLiquidityPoolDAIBalanceMilton === actualLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`);

        assert(expectedLiquidityProviderDAIBalance === actualDAIBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`);

        const actualIpUSDCBalanceSender = BigInt(await iporTokenUsdc.balanceOf(liquidityProvider));
        const actualUSDCBalanceMilton = BigInt(await tokenUsdc.balanceOf(milton.address));

        const actualLiquidityPoolUSDCBalanceMilton = BigInt(await (await miltonStorage.balances(tokenUsdc.address)).liquidityPool);
        const actualUSDCBalanceSender = BigInt(await tokenUsdc.balanceOf(liquidityProvider));

        assert(expectedipUSDCBalanceSender === actualIpUSDCBalanceSender,
            `Incorrect IPOR Token USDC balance on user for asset ${tokenUsdc.address} actual: ${actualIpUSDCBalanceSender}, expected: ${expectedipUSDCBalanceSender}`);

        assert(expectedUSDCBalanceMilton === actualUSDCBalanceMilton,
            `Incorrect USDC balance on Milton for asset ${tokenUsdc.address} actual: ${actualUSDCBalanceMilton}, expected: ${expectedUSDCBalanceMilton}`);

        assert(expectedLiquidityPoolUSDCBalanceMilton === actualLiquidityPoolUSDCBalanceMilton,
            `Incorrect USDC Liquidity Pool Balance on Milton for asset ${tokenUsdc.address} actual: ${actualLiquidityPoolUSDCBalanceMilton}, expected: ${expectedLiquidityPoolUSDCBalanceMilton}`);

        assert(expectedLiquidityProviderUSDCBalance === actualUSDCBalanceSender,
            `Incorrect USDC balance on Liquidity Provider for asset ${tokenUsdc.address} actual: ${actualUSDCBalanceSender}, expected: ${expectedLiquidityProviderUSDCBalance}`);
    });

    it('should redeem ipDAI, should redeem ipUSDC, cool off period passed for ipDAI and for ipUSDC, two users', async () => {
        //given
        await setupTokenDaiInitialValues();
        await setupTokenUsdcInitialValues();

        await setupIporTokenDaiInitialValues();
        await setupIporTokenUsdcInitialValues();

        let liquidityAmount = testUtils.MILTON_14_000_USD;
        let withdrawAmount = testUtils.MILTON_10_000_USD;

        let expectedipDAIBalanceSender = BigInt("4000000000000000000000");
        let expectedDAIBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderDAIBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolDAIBalanceMilton = expectedDAIBalanceMilton;

        let expectedipUSDCBalanceSender = BigInt("4000000000000000000000");
        let expectedUSDCBalanceMilton = BigInt("4000000000000000000000");
        let expectedLiquidityProviderUSDCBalance = BigInt("9996000000000000000000000");
        let expectedLiquidityPoolUSDCBalanceMilton = expectedUSDCBalanceMilton;

        let actionTimestamp = Math.floor(Date.now() / 1000);
        let daiUser = userOne;
        let usdcUser = userTwo;
        await joseph.test_provideLiquidity(tokenUsdc.address, liquidityAmount, actionTimestamp, {from: usdcUser});
        await joseph.test_provideLiquidity(tokenDai.address, liquidityAmount, actionTimestamp, {from: daiUser});

        let redeemTimestamp = actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS;

        //when
        await joseph.test_redeem(tokenUsdc.address, withdrawAmount, redeemTimestamp, {from: usdcUser});
        await joseph.test_redeem(tokenDai.address, withdrawAmount, redeemTimestamp, {from: daiUser});

        //then
        const actualIpDAIBalanceSender = BigInt(await iporTokenDai.balanceOf(daiUser));
        const actualDAIBalanceMilton = BigInt(await tokenDai.balanceOf(milton.address));
        const actualLiquidityPoolDAIBalanceMilton = BigInt(await (await miltonStorage.balances(tokenDai.address)).liquidityPool);
        const actualDAIBalanceSender = BigInt(await tokenDai.balanceOf(daiUser));

        assert(expectedipDAIBalanceSender === actualIpDAIBalanceSender,
            `Incorrect IPOR Token DAI balance on user for asset ${tokenDai.address} actual: ${actualIpDAIBalanceSender}, expected: ${expectedipDAIBalanceSender}`);

        assert(expectedDAIBalanceMilton === actualDAIBalanceMilton,
            `Incorrect DAI balance on Milton for asset ${tokenDai.address} actual: ${actualDAIBalanceMilton}, expected: ${expectedDAIBalanceMilton}`);

        assert(expectedLiquidityPoolDAIBalanceMilton === actualLiquidityPoolDAIBalanceMilton,
            `Incorrect DAI Liquidity Pool Balance on Milton for asset ${tokenDai.address} actual: ${actualLiquidityPoolDAIBalanceMilton}, expected: ${expectedLiquidityPoolDAIBalanceMilton}`);

        assert(expectedLiquidityProviderDAIBalance === actualDAIBalanceSender,
            `Incorrect DAI balance on Liquidity Provider for asset ${tokenDai.address} actual: ${actualDAIBalanceSender}, expected: ${expectedLiquidityProviderDAIBalance}`);

        const actualIpUSDCBalanceSender = BigInt(await iporTokenUsdc.balanceOf(usdcUser));
        const actualUSDCBalanceMilton = BigInt(await tokenUsdc.balanceOf(milton.address));

        const actualLiquidityPoolUSDCBalanceMilton = BigInt(await (await miltonStorage.balances(tokenUsdc.address)).liquidityPool);
        const actualUSDCBalanceSender = BigInt(await tokenUsdc.balanceOf(usdcUser));

        assert(expectedipUSDCBalanceSender === actualIpUSDCBalanceSender,
            `Incorrect IPOR Token USDC balance on user for asset ${tokenUsdc.address} actual: ${actualIpUSDCBalanceSender}, expected: ${expectedipUSDCBalanceSender}`);

        assert(expectedUSDCBalanceMilton === actualUSDCBalanceMilton,
            `Incorrect USDC balance on Milton for asset ${tokenUsdc.address} actual: ${actualUSDCBalanceMilton}, expected: ${expectedUSDCBalanceMilton}`);

        assert(expectedLiquidityPoolUSDCBalanceMilton === actualLiquidityPoolUSDCBalanceMilton,
            `Incorrect USDC Liquidity Pool Balance on Milton for asset ${tokenUsdc.address} actual: ${actualLiquidityPoolUSDCBalanceMilton}, expected: ${expectedLiquidityPoolUSDCBalanceMilton}`);

        assert(expectedLiquidityProviderUSDCBalance === actualUSDCBalanceSender,
            `Incorrect USDC balance on Liquidity Provider for asset ${tokenUsdc.address} actual: ${actualUSDCBalanceSender}, expected: ${expectedLiquidityProviderUSDCBalance}`);
    });

    it('should NOT redeem - user doesnt have enough tokens in Joseph book - case 1', async () => {
        //given
        let actionTimestamp = Math.floor(Date.now() / 1000);

        let oldJoseph = await iporAddressesManager.getAddress("JOSEPH");
        await iporAddressesManager.setAddress("JOSEPH", admin);
        await iporTokenDai.mint(userThree, testUtils.MILTON_10_000_USD);
        await iporAddressesManager.setAddress("JOSEPH", oldJoseph);

        //when
        await testUtils.assertError(
            //when
            joseph.test_redeem(tokenDai.address, testUtils.MILTON_10_000_USD, actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: userThree}),
            //then
            'IPOR_48'
        );
    });

    it('should NOT redeem - user doesnt have enough tokens in Joseph book - transfer Ipor Tokens between users is not enough', async () => {
        //given
        await setupTokenDaiInitialValues();
        let actionTimestamp = Math.floor(Date.now() / 1000);
        await joseph.test_provideLiquidity(tokenDai.address, testUtils.MILTON_10_000_USD, actionTimestamp, {from: liquidityProvider});

        await iporTokenDai.transfer(userThree, testUtils.MILTON_10_000_USD, {from: liquidityProvider});

        //when
        await testUtils.assertError(
            //when
            joseph.test_redeem(tokenDai.address, testUtils.MILTON_10_000_USD, actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: userThree}),
            //then
            'IPOR_48'
        );
    });

    it('should NOT redeem - user doesnt have enough tokens in Joseph book - User has enough Ipor Tokens but not minted by Joseph', async () => {
        //given
        await setupTokenDaiInitialValues();
        let actionTimestamp = Math.floor(Date.now() / 1000);
        await joseph.test_provideLiquidity(tokenDai.address, testUtils.MILTON_10_000_USD, actionTimestamp, {from: liquidityProvider});
        await joseph.test_provideLiquidity(tokenDai.address, testUtils.MILTON_10_000_USD, actionTimestamp, {from: userThree});

        await iporTokenDai.transfer(userThree, testUtils.MILTON_10_000_USD, {from: liquidityProvider});

        //when
        await testUtils.assertError(
            //when
            joseph.test_redeem(tokenDai.address,
                testUtils.MILTON_10_000_USD + testUtils.MILTON_10_000_USD,
                actionTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, {from: userThree}),
            //then
            'IPOR_48'
        );
    });

    const getStandardDerivativeParams = () => {
        return {
            asset: tokenDai.address,
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            collateralizationFactor: BigInt(10000000000000000000),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
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
    const setupIporTokenDaiInitialValues = async () => {
        await iporAddressesManager.setAddress("MILTON", userOne);
        let lpBalance = BigInt(await iporTokenDai.balanceOf(liquidityProvider));
        if (lpBalance > 0) {
            await iporTokenDai.burn(liquidityProvider, accounts[5], lpBalance, {from: userOne});
        }
        await iporAddressesManager.setAddress("MILTON", milton.address);
    }

    const setupIporTokenUsdcInitialValues = async () => {
        await iporAddressesManager.setAddress("MILTON", userOne);
        let lpBalance = BigInt(await iporTokenUsdc.balanceOf(liquidityProvider));
        if (lpBalance > 0) {
            await iporTokenUsdc.burn(liquidityProvider, accounts[5], lpBalance, {from: userOne});
        }
        await iporAddressesManager.setAddress("MILTON", milton.address);
    }
});
