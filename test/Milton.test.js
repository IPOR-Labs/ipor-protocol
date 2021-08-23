const testUtils = require("./TestUtils.js");
const {time, BN} = require("@openzeppelin/test-helpers");
const MiltonConfiguration = artifacts.require('MiltonConfiguration');
const TestMiltonV1Proxy = artifacts.require('TestMiltonV1Proxy');
const TestWarrenProxy = artifacts.require('TestWarrenProxy');
const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const DerivativeLogic = artifacts.require('DerivativeLogic');
const SoapIndicatorLogic = artifacts.require('SoapIndicatorLogic');
const TotalSoapIndicatorLogic = artifacts.require('TotalSoapIndicatorLogic');
const MiltonAddressesManager = artifacts.require('MiltonAddressesManager');
const MiltonDevToolDataProvider = artifacts.require('MiltonDevToolDataProvider');

contract('Milton', (accounts) => {

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
    let derivativeLogic = null;
    let soapIndicatorLogic = null;
    let totalSoapIndicatorLogic = null;
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let warren = null;
    let miltonConfiguration = null;
    let miltonAddressesManager = null;
    let miltonDevToolDataProvider = null;

    before(async () => {
        derivativeLogic = await DerivativeLogic.deployed();
        soapIndicatorLogic = await SoapIndicatorLogic.deployed();
        totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deployed();
        miltonConfiguration = await MiltonConfiguration.deployed();
        miltonAddressesManager = await MiltonAddressesManager.deployed();
        miltonDevToolDataProvider = await MiltonDevToolDataProvider.deployed();
        await miltonAddressesManager.setAddress("MILTON_CONFIGURATION", miltonConfiguration.address);

    });

    beforeEach(async () => {

        warren = await TestWarrenProxy.new();

        //10 000 000 000 000 USD
        tokenUsdt = await UsdtMockedToken.new(totalSupply6Decimals, 6);
        //10 000 000 000 000 USD
        //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
        tokenUsdc = await UsdcMockedToken.new(totalSupply18Decimals, 18);
        //10 000 000 000 000 USD
        tokenDai = await DaiMockedToken.new(totalSupply18Decimals, 18);


        milton = await TestMiltonV1Proxy.new(miltonAddressesManager.address);

        await warren.addUpdater(userOne);

        for (let i = 1; i < accounts.length - 2; i++) {
            await tokenUsdt.transfer(accounts[i], userSupply6Decimals);
            //TODO: zrobic obsługę 6 miejsc po przecinku! - userSupply18Decimals
            await tokenUsdc.transfer(accounts[i], userSupply18Decimals);
            await tokenDai.transfer(accounts[i], userSupply18Decimals);

            //AMM has rights to spend money on behalf of user
            await tokenUsdt.approve(milton.address, totalSupply6Decimals, {from: accounts[i]});
            //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
            await tokenUsdc.approve(milton.address, totalSupply18Decimals, {from: accounts[i]});
            await tokenDai.approve(milton.address, totalSupply18Decimals, {from: accounts[i]});
        }

        await miltonAddressesManager.setAddress("WARREN", warren.address);
        await miltonAddressesManager.setAddress("MILTON", milton.address);

        await miltonAddressesManager.setAddress("USDT", tokenUsdt.address);
        await miltonAddressesManager.setAddress("USDC", tokenUsdc.address);
        await miltonAddressesManager.setAddress("DAI", tokenDai.address);

    });
    //
    // it('should NOT open position because deposit amount too low', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = 0;
    //     let slippageValue = 3;
    //     let direction = 0;
    //     let leverage = 10;
    //
    //     await testUtils.assertError(
    //         //when
    //         milton.openPosition(asset, depositAmount, slippageValue, leverage, direction),
    //         //then
    //         'IPOR_4'
    //     );
    // });
    //
    //
    // it('should NOT open position because slippage too low', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = BigInt("30000000000000000001");
    //     let slippageValue = 0;
    //     let direction = 0;
    //     let leverage = 10;
    //
    //     await testUtils.assertError(
    //         //when
    //         milton.openPosition(asset, depositAmount, slippageValue, leverage, direction),
    //         //then
    //         'IPOR_5'
    //     );
    // });
    //
    // it('should NOT open position because slippage too high', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = BigInt("30000000000000000001");
    //     let slippageValue = web3.utils.toBN(1e20);
    //     let theOne = web3.utils.toBN(1);
    //     slippageValue = slippageValue.add(theOne);
    //     let direction = 0;
    //     let leverage = 10;
    //
    //     await testUtils.assertError(
    //         //when
    //         milton.openPosition(asset, depositAmount, slippageValue, leverage, direction),
    //         //then
    //         'IPOR_9'
    //     );
    // });
    //
    // it('should NOT open position because deposit amount too high', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = BigInt("1000000000000000000000001")
    //     let slippageValue = 3;
    //     let direction = 0;
    //     let leverage = 10;
    //
    //     await testUtils.assertError(
    //         //when
    //         milton.openPosition(asset, depositAmount, slippageValue, leverage, direction),
    //         //then
    //         'IPOR_10'
    //     );
    // });
    //
    // it('should open pay fixed position - simple case DAI', async () => {
    //     //given
    //     const params = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: 0,
    //         openTimestamp: Math.floor(Date.now() / 1000),
    //         from: userTwo
    //     }
    //     await warren.updateIndex(params.asset, testUtils.MILTON_3_PERCENTAGE, {from: userOne});
    //
    //     //when
    //     await milton.openPosition(
    //         params.asset, params.totalAmount,
    //         params.slippageValue, params.leverage,
    //         params.direction, {from: userTwo});
    //
    //     //then
    //     const expectedDerivativesTotalBalance = BigInt("9870300000000000000000");
    //
    //     await assertExpectedValues(
    //         params.asset,
    //         userTwo,
    //         userTwo,
    //         testUtils.ZERO,
    //         testUtils.MILTON_10_000_USD,
    //         BigInt("9990000000000000000000000"),
    //         BigInt("9990000000000000000000000"),
    //         BigInt("99700000000000000000"),
    //         1,
    //         BigInt("9870300000000000000000"),
    //         testUtils.MILTON_20_USD,
    //         BigInt("0")
    //     );
    //
    //     const actualDerivativesTotalBalance = BigInt((await milton.balances(params.asset)).derivatives);
    //
    //     assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
    //         `Incorrect derivatives total balance for ${params.asset} ${actualDerivativesTotalBalance}, expected ${expectedDerivativesTotalBalance}`)
    //
    // });
    //
    // // TODO: implement it
    // // it('should open receive fixed position - simple case DAI', async () => {
    // //
    // // });
    //
    // it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
    //     let incomeTax = BigInt("0");
    //     let expectedAMMTokenBalance = BigInt("109700000000000000000");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9999890300000000000000000");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9999890300000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("99700000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_3_PERCENTAGE, testUtils.MILTON_3_PERCENTAGE, 0, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity', async () => {
    //     let incomeTax = BigInt("6760479452054794520");
    //     let expectedAMMTokenBalance = BigInt("177304794520547945204");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9999822695205479452054796");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9999822695205479452054796");
    //     let expectedLiquidityPoolTotalBalance = BigInt("167304794520547945204") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_365_PERCENTAGE, testUtils.MILTON_365_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should NOT open position because Liquidity Pool is to low', async () => {
    //     //given
    //     const params = {
    //         asset: "DAI",
    //         totalAmount: BigInt("10000000000000000000000"), //10 000 USD
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: 0,
    //         openTimestamp: Math.floor(Date.now() / 1000),
    //         from: userTwo
    //     }
    //
    //     let closePositionTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS
    //
    //     await warren.test_updateIndex(params.asset, BigInt("10000000000000000"), params.openTimestamp, {from: userOne});
    //     await openPositionFunc(params);
    //     await warren.test_updateIndex(params.asset, BigInt("1600000000000000000"), params.openTimestamp, {from: userOne});
    //     await warren.test_updateIndex(params.asset, BigInt("50000000000000000"), closePositionTimestamp, {from: userOne});
    //
    //     //when
    //     await testUtils.assertError(
    //         //when
    //         milton.test_closePosition(1, closePositionTimestamp, {from: userTwo}),
    //         //then
    //         'IPOR_14'
    //     );
    //
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("9980000000000000000000");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9990020000000000000000000");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9990020000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("784215616438356167764");
    //     let expectedAMMTokenBalance = BigInt("7951856164383561677637");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9992048143835616438322363");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9992048143835616438322363");
    //     let expectedLiquidityPoolTotalBalance = BigInt("7941856164383561677637") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("848575380821917805109");
    //     let expectedAMMTokenBalance = BigInt("8595453808219178051093");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9991404546191780821948907");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9991404546191780821948907");
    //     let expectedLiquidityPoolTotalBalance = BigInt("8585453808219178051093") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
    //     let expectedLiquidityPoolTotalBalance = BigInt("629400000000000000000");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("770694657534246573179");
    //     let expectedAMMTokenBalance = BigInt("2802753424657534268209") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10007597246575342465731791") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10007597246575342465731791") - incomeTax;
    //     let expectedLiquidityPoolTotalBalance = BigInt("2792753424657534268209");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_120_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
    //     let expectedLiquidityPoolTotalBalance = BigInt("629400000000000000000");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("630617523287671234364");
    //     let expectedAMMTokenBalance = BigInt("4203524767123287656360") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10006196475232876712343640") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10006196475232876712343640") - incomeTax;
    //     let expectedLiquidityPoolTotalBalance = BigInt("4193524767123287656360");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_50_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009740600000000000000000") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10000020000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("629400000000000000000");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userThree,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
    //     //given
    //     const params = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: 0,
    //         openTimestamp: Math.floor(Date.now() / 1000),
    //         from: userTwo
    //     }
    //
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
    //     await openPositionFunc(params);
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
    //     let endTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});
    //     await milton.provideLiquidity(params.asset, testUtils.MILTON_10_400_USD, {from: liquidityProvider})
    //
    //     //when
    //     await testUtils.assertError(
    //         //when
    //         milton.test_closePosition(1, endTimestamp, {from: userThree}),
    //         //then
    //         'IPOR_16');
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009740600000000000000000") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10000020000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("629400000000000000000");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userThree,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("630617523287671234364");
    //     let expectedAMMTokenBalance = BigInt("4203524767123287656360") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10006176475232876712343640") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10000020000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("4193524767123287656360");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userThree,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_50_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("9980000000000000000000");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9990000000000000000000000");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10000020000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userThree,
    //         testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
    //         testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
    //     //given
    //     const params = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: 0,
    //         openTimestamp: Math.floor(Date.now() / 1000),
    //         from: userTwo
    //     }
    //
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
    //     await openPositionFunc(params);
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
    //     let endTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});
    //     await milton.provideLiquidity(params.asset, testUtils.MILTON_10_400_USD, {from: liquidityProvider})
    //
    //     //when
    //     await testUtils.assertError(
    //         //when
    //         milton.test_closePosition(1, endTimestamp, {from: userThree}),
    //         //then
    //         'IPOR_16');
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("848575380821917805109");
    //     let expectedAMMTokenBalance = BigInt("8595453808219178051093");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9991384546191780821948907");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10000020000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("8585453808219178051093") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userThree,
    //         testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
    //         testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("9980000000000000000000");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9990000000000000000000000");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10000020000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userThree,
    //         testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
    //         testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
    //     let incomeTax = BigInt("6760479452054792492");
    //     let expectedAMMTokenBalance = BigInt("177304794520547924923");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9999822695205479452075077");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9999822695205479452075077");
    //     let expectedLiquidityPoolTotalBalance = BigInt("167304794520547924923") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_3_PERCENTAGE, testUtils.MILTON_3_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    //
    // it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price changed 25%, before maturity', async () => {
    //     let incomeTax = BigInt("6760479452054794520");
    //     let expectedAMMTokenBalance = BigInt("177304794520547945204");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9999822695205479452054796");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9999822695205479452054796");
    //     let expectedLiquidityPoolTotalBalance = BigInt("167304794520547945204") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_365_PERCENTAGE, testUtils.MILTON_365_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
    //     let expectedLiquidityPoolTotalBalance = BigInt("629400000000000000000");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("770694657534246578723");
    //     let expectedAMMTokenBalance = BigInt("2802753424657534212773") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10007597246575342465787227") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10007597246575342465787227") - incomeTax;
    //     let expectedLiquidityPoolTotalBalance = BigInt("2792753424657534212773");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("9980000000000000000000");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9990020000000000000000000");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9990020000000000000000000") ;
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000")- incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("784215616438356162220");
    //     let expectedAMMTokenBalance = BigInt("7951856164383561622201");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9992048143835616438377799");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9992048143835616438377799") ;
    //     let expectedLiquidityPoolTotalBalance = BigInt("7941856164383561622201")- incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_120_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
    //     let expectedLiquidityPoolTotalBalance = BigInt("629400000000000000000");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax,
    //         testUtils.ZERO
    //     );
    // });
    //
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
    //         let incomeTax = BigInt("833431906849315065383");
    //         let expectedAMMTokenBalance = BigInt("2175380931506849346167") + incomeTax;
    //         let expectedLiquidityPoolTotalBalance = BigInt("2165380931506849346167");
    //         let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10008224619068493150653833") - incomeTax;
    //         let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10008224619068493150653833") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let depositAmount = BigInt("9870300000000000000000");
    //     let expectedAMMTokenBalance = BigInt("9980000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000") - incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9990020000000000000000000");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_120_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax, testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("645760997260273974090");
    //     let expectedAMMTokenBalance = BigInt("6567309972602739740899");
    //     let expectedLiquidityPoolTotalBalance = BigInt("6557309972602739740899") - incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9993432690027397260259101");
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userTwo,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_50_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut, //expectedOpenerUserTokenBalanceAfterPayOut
    //         BigInt("9993432690027397260259101"), //expectedCloserUserTokenBalanceAfterPayOut
    //         expectedLiquidityPoolTotalBalance, //expectedLiquidityPoolTotalBalance
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax,
    //         testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
    //     let expectedLiquidityPoolTotalBalance = BigInt("629400000000000000000") ;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009740600000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userThree,
    //         testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance, //expectedAMMTokenBalance
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         expectedLiquidityPoolTotalBalance, //expectedLiquidityPoolTotalBalance
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax,
    //         testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
    //     //given
    //     const params = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: 1,
    //         openTimestamp: Math.floor(Date.now() / 1000),
    //         from: userTwo
    //     }
    //
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
    //     await openPositionFunc(params);
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
    //     let endTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});
    //     await milton.provideLiquidity(params.asset, testUtils.MILTON_10_400_USD, {from: liquidityProvider})
    //
    //     //when
    //     await testUtils.assertError(
    //         //when
    //         milton.test_closePosition(1, endTimestamp, {from: userThree}),
    //         //then
    //         'IPOR_16');
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("9980000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userThree,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
    //         BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax,
    //         testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
    //     //given
    //     const params = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: 1,
    //         openTimestamp: Math.floor(Date.now() / 1000),
    //         from: userTwo
    //     }
    //
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
    //     await openPositionFunc(params);
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
    //     let endTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     await warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});
    //
    //     //when
    //     await testUtils.assertError(
    //         //when
    //         milton.test_closePosition(1, endTimestamp, {from: userThree}),
    //         //then
    //         'IPOR_16');
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009740600000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userThree,
    //         testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance, //expectedAMMTokenBalance
    //         expectedOpenerUserTokenBalanceAfterPayOut, //expectedOpenerUserTokenBalanceAfterPayOut
    //         BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax,
    //         testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("833431906849315065383");
    //     let expectedAMMTokenBalance = BigInt("2175380931506849346167") + incomeTax;
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10008204619068493150653833") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userThree,
    //         testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         BigInt("2165380931506849346167"), //expectedLiquidityPoolTotalBalance
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax,
    //         testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userThree,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.ZERO,
    //         BigInt("9980000000000000000000"), //expectedAMMTokenBalance
    //         BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
    //         BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax,
    //         testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("645760997260273974090");
    //     let expectedLiquidityPoolTotalBalance = BigInt("6557309972602739740899") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userThree,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_50_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.ZERO,
    //         BigInt("6567309972602739740899"), //expectedAMMTokenBalance
    //         BigInt("9993412690027397260259101"), //expectedOpenerUserTokenBalanceAfterPayOut
    //         BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax, //treasury total balance
    //         testUtils.ZERO
    //     );
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
    //     let incomeTax = BigInt("987030000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.ZERO,
    //         BigInt("9980000000000000000000"), //expectedAMMTokenBalance
    //         BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
    //         BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         expectedLiquidityPoolTotalBalance, //expectedLiquidityPoolTotalBalance
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax, //treasury total balance
    //         testUtils.ZERO
    //     );
    // });
    //
    //
    // it('should NOT close position, because incorrect derivative Id', async () => {
    //     //given
    //     let direction = 0;
    //     let openerUserAddress = userTwo;
    //     let closerUserAddress = userTwo;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParamsFirst = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: openerUserAddress
    //     }
    //     await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
    //     await openPositionFunc(derivativeParamsFirst);
    //
    //     await testUtils.assertError(
    //         //when
    //         milton.test_closePosition(0, openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: closerUserAddress}),
    //         //then
    //         'IPOR_22'
    //     );
    // });
    //
    // it('should NOT close position, because derivative has incorrect status', async () => {
    //     //given
    //     let direction = 0;
    //     let openerUserAddress = userTwo;
    //     let closerUserAddress = userTwo;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParamsFirst = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: openerUserAddress
    //     }
    //     await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
    //     await openPositionFunc(derivativeParamsFirst);
    //
    //     const derivativeParams25days = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
    //         from: openerUserAddress
    //     }
    //     await openPositionFunc(derivativeParams25days);
    //
    //     let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS
    //
    //     await milton.test_closePosition(1, endTimestamp, {from: closerUserAddress})
    //
    //     await testUtils.assertError(
    //         //when
    //         milton.test_closePosition(1, endTimestamp, {from: closerUserAddress}),
    //         //then
    //         'IPOR_23'
    //     );
    // });
    //
    //
    // it('should close only one position - close first position', async () => {
    //     //given
    //     let direction = 0;
    //     let openerUserAddress = userTwo;
    //     let closerUserAddress = userTwo;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParamsFirst = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: openerUserAddress
    //     }
    //     await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
    //     await openPositionFunc(derivativeParamsFirst);
    //
    //     const derivativeParams25days = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
    //         from: openerUserAddress
    //     }
    //     await openPositionFunc(derivativeParams25days);
    //     let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS
    //     let expectedOpenedPositionsVol = 1;
    //     let expectedDerivativeId = BigInt(2);
    //
    //     //when
    //     await milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});
    //
    //     //then
    //     let actualDerivatives = await milton.getPositions();
    //     let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);
    //
    //     assert(expectedOpenedPositionsVol === actualOpenedPositionsVol,
    //         `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`)
    //
    //     let oneDerivative = actualDerivatives[0];
    //
    //     assert(expectedDerivativeId === BigInt(oneDerivative.id),
    //         `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`)
    // });
    //
    // it('should close only one position - close last position', async () => {
    //     //given
    //     let direction = 0;
    //     let openerUserAddress = userTwo;
    //     let closerUserAddress = userTwo;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParamsFirst = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: openerUserAddress
    //     }
    //     await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
    //     await openPositionFunc(derivativeParamsFirst);
    //
    //     const derivativeParams25days = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
    //         from: openerUserAddress
    //     }
    //     await openPositionFunc(derivativeParams25days);
    //     let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS
    //     let expectedOpenedPositionsVol = 1;
    //     let expectedDerivativeId = BigInt(1);
    //
    //     //when
    //     await milton.test_closePosition(2, endTimestamp, {from: closerUserAddress});
    //
    //     //then
    //     let actualDerivatives = await milton.getPositions();
    //     let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);
    //
    //     assert(expectedOpenedPositionsVol === actualOpenedPositionsVol,
    //         `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`)
    //
    //     let oneDerivative = actualDerivatives[0];
    //
    //     assert(expectedDerivativeId === BigInt(oneDerivative.id),
    //         `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`)
    //
    // });
    //
    // it('should open many positions and arrays with ids have correct state, one user', async () => {
    //     //given
    //     let direction = 0;
    //     let openerUserAddress = userTwo;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParams = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: openerUserAddress
    //     }
    //     await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
    //
    //     let expectedUserDerivativeIdsLength = 3
    //     let expectedDerivativeIdsLength = 3;
    //
    //     //when
    //     await openPositionFunc(derivativeParams);
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     await openPositionFunc(derivativeParams);
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     await openPositionFunc(derivativeParams);
    //
    //
    //     //then
    //     let actualUserDerivativeIds = await milton.getUserDerivativeIds(openerUserAddress);
    //     let actualDerivativeIds = await milton.getDerivativeIds();
    //
    //
    //     assert(expectedUserDerivativeIdsLength === actualUserDerivativeIds.length,
    //         `Incorrect user derivative ids length actual: ${actualUserDerivativeIds.length}, expected: ${expectedUserDerivativeIdsLength}`)
    //     assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
    //         `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)
    //
    //     await assertMiltonDerivativeItem(1, 0, 0);
    //     await assertMiltonDerivativeItem(2, 1, 1);
    //     await assertMiltonDerivativeItem(3, 2, 2);
    // });
    //
    // it('should open many positions and arrays with ids have correct state, two users', async () => {
    //     //given
    //     let direction = 0;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParams = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: userTwo
    //     }
    //     await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
    //
    //     let expectedUserDerivativeIdsLengthFirst = 2;
    //     let expectedUserDerivativeIdsLengthSecond = 1;
    //     let expectedDerivativeIdsLength = 3;
    //
    //     //when
    //     await openPositionFunc(derivativeParams);
    //
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     derivativeParams.from = userThree;
    //     await openPositionFunc(derivativeParams);
    //
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     derivativeParams.from = userTwo;
    //     await openPositionFunc(derivativeParams);
    //
    //     //then
    //     let actualUserDerivativeIdsFirst = await milton.getUserDerivativeIds(userTwo);
    //     let actualUserDerivativeIdsSecond = await milton.getUserDerivativeIds(userThree);
    //     let actualDerivativeIds = await milton.getDerivativeIds();
    //
    //
    //     assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
    //         `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
    //     assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
    //         `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
    //     assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
    //         `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)
    //
    //     await assertMiltonDerivativeItem(1, 0, 0);
    //     await assertMiltonDerivativeItem(2, 1, 0);
    //     await assertMiltonDerivativeItem(3, 2, 1);
    //
    // });
    //
    // it('should open many positions and close one position and arrays with ids have correct state, two users', async () => {
    //     //given
    //     let direction = 0;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParams = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: userTwo
    //     }
    //     await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
    //
    //     let expectedUserDerivativeIdsLengthFirst = 2;
    //     let expectedUserDerivativeIdsLengthSecond = 0;
    //     let expectedDerivativeIdsLength = 2;
    //
    //     await openPositionFunc(derivativeParams);
    //
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     derivativeParams.from = userThree;
    //     await openPositionFunc(derivativeParams);
    //
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     derivativeParams.from = userTwo;
    //     await openPositionFunc(derivativeParams);
    //
    //     //when
    //     await milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
    //
    //     //then
    //     let actualUserDerivativeIdsFirst = await milton.getUserDerivativeIds(userTwo);
    //     let actualUserDerivativeIdsSecond = await milton.getUserDerivativeIds(userThree);
    //     let actualDerivativeIds = await milton.getDerivativeIds();
    //
    //
    //     assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
    //         `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
    //     assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
    //         `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
    //     assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
    //         `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)
    //
    //     await assertMiltonDerivativeItem(1, 0, 0);
    //     await assertMiltonDerivativeItem(3, 1, 1);
    // });
    //
    // it('should open many positions and close two positions and arrays with ids have correct state, two users', async () => {
    //     //given
    //     let direction = 0;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParams = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: userTwo
    //     }
    //     await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
    //
    //     let expectedUserDerivativeIdsLengthFirst = 1;
    //     let expectedUserDerivativeIdsLengthSecond = 0;
    //     let expectedDerivativeIdsLength = 1;
    //
    //     await openPositionFunc(derivativeParams);
    //
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     derivativeParams.from = userThree;
    //     await openPositionFunc(derivativeParams);
    //
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     derivativeParams.from = userTwo;
    //     await openPositionFunc(derivativeParams);
    //
    //     //when
    //     await milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
    //     await milton.test_closePosition(3, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userTwo});
    //
    //     //then
    //     let actualUserDerivativeIdsFirst = await milton.getUserDerivativeIds(userTwo);
    //     let actualUserDerivativeIdsSecond = await milton.getUserDerivativeIds(userThree);
    //     let actualDerivativeIds = await milton.getDerivativeIds();
    //
    //
    //     assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
    //         `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
    //     assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
    //         `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
    //     assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
    //         `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)
    //
    //     await assertMiltonDerivativeItem(1, 0, 0);
    //
    // });
    //
    // it('should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1', async () => {
    //     //given
    //     let direction = 0;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParams = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: userThree
    //     }
    //     await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
    //
    //     let expectedUserDerivativeIdsLengthFirst = 0;
    //     let expectedUserDerivativeIdsLengthSecond = 0;
    //     let expectedDerivativeIdsLength = 0;
    //
    //     //position 1, user first
    //     await openPositionFunc(derivativeParams);
    //
    //     //position 2, user second
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     await openPositionFunc(derivativeParams);
    //
    //     //when
    //     await milton.test_closePosition(1, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
    //     await milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS, {from: userThree});
    //
    //
    //     //then
    //     let actualUserDerivativeIdsFirst = await milton.getUserDerivativeIds(userTwo);
    //     let actualUserDerivativeIdsSecond = await milton.getUserDerivativeIds(userTwo);
    //     let actualDerivativeIds = await milton.getDerivativeIds();
    //
    //
    //     assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
    //         `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
    //     assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
    //         `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
    //     assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
    //         `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)
    //
    //
    // });
    //
    // it('should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1 with minus 3', async () => {
    //     //given
    //     let direction = 0;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParams = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: userThree
    //     }
    //     await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
    //
    //     let expectedUserDerivativeIdsLengthFirst = 0;
    //     let expectedUserDerivativeIdsLengthSecond = 0;
    //     let expectedDerivativeIdsLength = 0;
    //
    //     //position 1, user first
    //     await openPositionFunc(derivativeParams);
    //
    //     //position 2, user second
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS - 3;
    //     await openPositionFunc(derivativeParams);
    //
    //     //when
    //     await milton.test_closePosition(1, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
    //     await milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS, {from: userThree});
    //
    //
    //     //then
    //     let actualUserDerivativeIdsFirst = await milton.getUserDerivativeIds(userTwo);
    //     let actualUserDerivativeIdsSecond = await milton.getUserDerivativeIds(userTwo);
    //     let actualDerivativeIds = await milton.getDerivativeIds();
    //
    //
    //     assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
    //         `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
    //     assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
    //         `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
    //     assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
    //         `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)
    //
    //
    // });
    //
    // it('should open two positions and close one position - Arithmetic overflow - last byte difference - case 1', async () => {
    //     //given
    //     let direction = 0;
    //     let iporValueBeforeOpenPosition = testUtils.MILTON_3_PERCENTAGE;
    //     let openTimestamp = Math.floor(Date.now() / 1000);
    //
    //     const derivativeParams = {
    //         asset: "DAI",
    //         totalAmount: testUtils.MILTON_10_000_USD,
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: direction,
    //         openTimestamp: openTimestamp,
    //         from: userThree
    //     }
    //     await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
    //
    //     let expectedUserDerivativeIdsLengthFirst = 0;
    //     let expectedUserDerivativeIdsLengthSecond = 0;
    //     let expectedDerivativeIdsLength = 0;
    //
    //     //position 1, user first
    //     derivativeParams.from = userThree;
    //     derivativeParams.direction = 0;
    //     await openPositionFunc(derivativeParams);
    //
    //     //position 2, user second
    //     derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
    //     derivativeParams.from = userThree;
    //     derivativeParams.direction = 0;
    //     await openPositionFunc(derivativeParams);
    //
    //     await milton.test_closePosition(1, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
    //
    //     //when
    //     await milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS, {from: userThree});
    //
    //
    //     //then
    //     let actualUserDerivativeIdsFirst = await milton.getUserDerivativeIds(userTwo);
    //     let actualUserDerivativeIdsSecond = await milton.getUserDerivativeIds(userTwo);
    //     let actualDerivativeIds = await milton.getDerivativeIds();
    //
    //
    //     assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
    //         `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
    //     assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
    //         `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
    //     assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
    //         `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)
    //
    // });
    //
    //
    it('should calculate income tax, 5%, Milton loses, user earns, |I| < D', async () => {
        await miltonConfiguration.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);
        let incomeTax = BigInt("416715953424657532692");
        let expectedAMMTokenBalance = BigInt("2175380931506849346167") + incomeTax;
        let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10008204619068493150653833") - incomeTax;
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userThree,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
            expectedAMMTokenBalance,
            expectedOpenerUserTokenBalanceAfterPayOut,
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2165380931506849346167"), //expectedLiquidityPoolTotalBalance
            0, testUtils.ZERO, testUtils.ZERO,
            incomeTax,
            testUtils.ZERO
        );
        await miltonConfiguration.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });

    it('should calculate income tax, 5%, Milton loses, user earns, |I| > D', async () => {
        await miltonConfiguration.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);
        let incomeTax = BigInt("493515000000000000000");
        let expectedAMMTokenBalance = BigInt("639400000000000000000") + incomeTax;
        let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
        let expectedCloserUserTokenBalanceAfterPayOut = BigInt("10009760600000000000000000") - incomeTax;
        let expectedLiquidityPoolTotalBalance = BigInt("629400000000000000000");
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS, testUtils.MILTON_10_400_USD,
            expectedAMMTokenBalance,
            expectedOpenerUserTokenBalanceAfterPayOut,
            expectedCloserUserTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalance,
            0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO
        );
        await miltonConfiguration.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });
    //
    // it('should calculate income tax, 5%, Milton earns, user loses, |I| < D', async () => {
    //     await miltonConfiguration.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);
    //     let incomeTax = BigInt("392107808219178083882");
    //     let expectedAMMTokenBalance = BigInt("7951856164383561677637");
    //     let expectedOpenerUserTokenBalanceAfterPayOut = BigInt("9992048143835616438322363");
    //     let expectedCloserUserTokenBalanceAfterPayOut = BigInt("9992048143835616438322363");
    //     let expectedLiquidityPoolTotalBalance = BigInt("7941856164383561677637") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 0, userTwo, userTwo,
    //         testUtils.MILTON_120_PERCENTAGE,
    //         testUtils.MILTON_5_PERCENTAGE,
    //         testUtils.PERIOD_25_DAYS_IN_SECONDS,
    //         testUtils.ZERO,
    //         expectedAMMTokenBalance,
    //         expectedOpenerUserTokenBalanceAfterPayOut,
    //         expectedCloserUserTokenBalanceAfterPayOut,
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax, testUtils.ZERO
    //     );
    //     await miltonConfiguration.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    // });
    //
    //
    // it('should calculate income tax, 5%, Milton earns, user loses, |I| > D', async () => {
    //     await miltonConfiguration.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);
    //     let incomeTax = BigInt("493515000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("9970000000000000000000") - incomeTax;
    //     await exetuceClosePositionTestCase(
    //         "DAI", 10, 1, userTwo, userThree,
    //         testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS, testUtils.ZERO,
    //         BigInt("9980000000000000000000"), //expectedAMMTokenBalance
    //         BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
    //         BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
    //         expectedLiquidityPoolTotalBalance,
    //         0, testUtils.ZERO, testUtils.ZERO,
    //         incomeTax,
    //         testUtils.ZERO
    //     );
    //     await miltonConfiguration.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);
    // });

    // it('should calculate income tax, 5%, Milton earns, user loses, to low liquidity pool', async () => {
    //
    // });

    // it('should calculate income tax, 5%, Milton loses, user earns, to low liquidity pool', async () => {
    //
    // });


    //TODO: dodac test 1 otwarta long, zmiana indeksu, 2 otwarta short, zmiana indeksu, zamykamy 1 i 2, soap = 0

    //TODO: dodać test w którym zmieniamy konfiguracje w MiltonConfiguration i widac zmiany w Milton

    //TODO: !!! dodaj testy do MiltonConfiguration


    //TODO: testy na strukturze MiltonDerivatives
    //TODO: dopisac test probujacy zamykac pozycje ktora nie istnieje

    //TODO: napisac test który sprawdza czy SoapIndicator podczas inicjalnego uruchomienia hypotheticalInterestCumulative jest równe testUtils.ZERO

    //TODO: test when ipor not ready yet
    //TODO: check initial IBT
    //TODO: create test when ipor index not yet created for specific asset

    //TODO: test na 1 sprwdzenie czy totalAmount wiekszy od fee
    //TODO: test na 2 sprwdzenie czy totalAmount wiekszy od fee (po przeliczeniu openingFeeAmount)
    //TODO: test na wysłanie USDT które ma 6 miejsc po przecinku i weryfikacja liczb


    //TODO: sprawdz w JS czy otworzenie nowej PIERWSZEJ derywatywy poprawnie wylicza SoapIndicator, hypotheticalInterestCumulative powinno być nadal testUtils.ZERO
    //TODO: sprawdz w JS czy otworzenej KOLEJNEJ derywatywy poprawnie wylicza SoapIndicator

    //TODO: add test which checks emited events!!!
    //TODO: dopisać test zmiany na przykład adresu warrena i sprawdzenia czy widzi to milton
    //TODO: dopisac test zmiany adresu usdt i sprawdzenia czy widzi to milton
    //TODO: test na IPOR_26 AMM_CANNOT_CLOSE_DERIVATE_LP_AND_DEPOSIT_IS_LOWER_THAN_INCOME_TAX
    //TODO: test na IPOR_27 AMM_CANNOT_CLOSE_DERIVATE_LP_AND_INTEREST_IS_LOWER_THAN_INCOME_TAX
    //TODO: test sprawdzajacy wykonaniue przxelewu eth na miltona


    const calculateSoap = async (params) => {
        return await milton.test_calculateSoap.call(params.asset, params.calculateTimestamp, {from: params.from});
    }

    const openPositionFunc = async (params) => {
        await milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.leverage,
            params.direction, {from: params.from});
    }

    const countOpenPositions = (derivatives) => {
        let count = 0;
        for (let i = 0; i < derivatives.length; i++) {
            if (derivatives[i].state == 0) {
                count++;
            }
        }
        return count;
    }

    const assertMiltonDerivativeItem = async (
        derivativeId,
        expectedIdsIndex,
        expectedUserDerivativeIdsIndex
    ) => {
        let actualDerivativeItem = await milton.getDerivativeItem(derivativeId);
        assert(BigInt(expectedIdsIndex) === BigInt(actualDerivativeItem.idsIndex),
            `Incorrect idsIndex for derivative id ${actualDerivativeItem.item.id} actual: ${actualDerivativeItem.idsIndex}, expected: ${expectedIdsIndex}`);
        assert(BigInt(expectedUserDerivativeIdsIndex) === BigInt(actualDerivativeItem.userDerivativeIdsIndex),
            `Incorrect userDerivativeIdsIndex for derivative id ${actualDerivativeItem.item.id} actual: ${actualDerivativeItem.userDerivativeIdsIndex}, expected: ${expectedUserDerivativeIdsIndex}`)
    }

    //TODO: add to every test..
    const assertDerivative = async (
        derivativeId,
        expectedDerivative
    ) => {

        // let actualDerivative = await milton.getOpenPosition(derivativeId);
        //
        // assertDerivativeItem('ID', expectedDerivative.id, actualDerivative.id);
        // assertDerivativeItem('State', expectedDerivative.state, actualDerivative.state);
        // assertDerivativeItem('Buyer', expectedDerivative.buyer, actualDerivative.buyer);
        // assertDerivativeItem('Asset', expectedDerivative.asset, actualDerivative.asset);
        // assertDerivativeItem('Direction', expectedDerivative.direction, actualDerivative.direction);
        // assertDerivativeItem('Deposit Amount', expectedDerivative.depositAmount, actualDerivative.depositAmount);
        // assertDerivativeItem('Liquidation Deposit Amount', expectedDerivative.fee.liquidationDepositAmount, actualDerivative.fee.liquidationDepositAmount);
        // assertDerivativeItem('Opening Amount Fee', expectedDerivative.fee.openingAmount, actualDerivative.fee.openingAmount);
        // assertDerivativeItem('IPOR Publication Amount Fee', expectedDerivative.fee.iporPublicationAmount, actualDerivative.fee.iporPublicationAmount);
        // assertDerivativeItem('Spread Percentage Fee', expectedDerivative.fee.spreadPercentage, actualDerivative.fee.spreadPercentage);
        // assertDerivativeItem('Leverage', expectedDerivative.leverage, actualDerivative.leverage);
        // assertDerivativeItem('Notional Amount', expectedDerivative.notionalAmount, actualDerivative.notionalAmount);
        // // assertDerivativeItem('Derivative starting timestamp', expectedDerivative.startingTimestamp, actualDerivative.startingTimestamp);
        // // assertDerivativeItem('Derivative ending timestamp', expectedDerivative.endingTimestamp, actualDerivative.endingTimestamp);
        // assertDerivativeItem('IPOR Index Value', expectedDerivative.indicator.iporIndexValue, actualDerivative.indicator.iporIndexValue);
        // assertDerivativeItem('IBT Price', expectedDerivative.indicator.ibtPrice, actualDerivative.indicator.ibtPrice);
        // assertDerivativeItem('IBT Quantity', expectedDerivative.indicator.ibtQuantity, actualDerivative.indicator.ibtQuantity);
        // assertDerivativeItem('Fixed Interest Rate', expectedDerivative.indicator.fixedInterestRate, actualDerivative.indicator.fixedInterestRate);
        // assertDerivativeItem('SOAP', expectedDerivative.indicator.soap, actualDerivative.indicator.soap);

    }

    const exetuceClosePositionTestCase = async function (
        asset,
        leverage,
        direction,
        openerUserAddress,
        closerUserAddress,
        iporValueBeforeOpenPosition,
        iporValueAfterOpenPosition,
        periodOfTimeElapsedInSeconds,
        providedLiquidityAmount,
        expectedAMMTokenBalance,
        expectedOpenerUserTokenBalanceAfterPayOut,
        expectedCloserUserTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalance,
        expectedOpenedPositions,
        expectedDerivativesTotalBalance,
        expectedLiquidationDepositFeeTotalBalance,
        expectedTreasuryTotalBalance,
        expectedSoap
    ) {
        //given
        const params = {
            asset: asset,
            totalAmount: testUtils.MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(params.asset, iporValueBeforeOpenPosition, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await warren.test_updateIndex(params.asset, iporValueAfterOpenPosition, params.openTimestamp, {from: userOne});

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;
        await warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});

        if (providedLiquidityAmount != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await milton.provideLiquidity(params.asset, providedLiquidityAmount, {from: liquidityProvider})
        }

        //when
        await milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        //then
        await assertExpectedValues(
            params.asset,
            openerUserAddress,
            closerUserAddress,
            providedLiquidityAmount,
            expectedAMMTokenBalance,
            expectedOpenerUserTokenBalanceAfterPayOut,
            expectedCloserUserTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalance,
            expectedOpenedPositions,
            expectedDerivativesTotalBalance,
            expectedLiquidationDepositFeeTotalBalance,
            expectedTreasuryTotalBalance
        );

        const soapParams = {
            asset: params.asset,
            calculateTimestamp: endTimestamp,
            expectedSoap: expectedSoap,
            from: openerUserAddress
        }
        await assertSoap(soapParams);
    }

    const assertExpectedValues = async function (
        asset,
        openerUserAddress,
        closerUserAddress,
        ammBalanceBeforePayout,
        expectedAMMTokenBalance,
        expectedOpenerUserTokenBalanceAfterPayOut,
        expectedCloserUserTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalance,
        expectedOpenedPositions,
        expectedDerivativesTotalBalance,
        expectedLiquidationDepositFeeTotalBalance,
        expectedTreasuryTotalBalance
    ) {
        let actualDerivatives = await milton.getPositions();
        let actualOpenPositionsVol = countOpenPositions(actualDerivatives);
        assert(expectedOpenedPositions === actualOpenPositionsVol,
            `Incorrect number of opened derivatives, actual:  ${actualOpenPositionsVol}, expected: ${expectedOpenedPositions}`)

        let expectedOpeningFeeTotalBalance = testUtils.MILTON_99__7_USD;
        let expectedPublicationFeeTotalBalance = testUtils.MILTON_10_USD;

        await assertBalances(
            asset,
            openerUserAddress,
            closerUserAddress,
            expectedOpenerUserTokenBalanceAfterPayOut,
            expectedCloserUserTokenBalanceAfterPayOut,
            expectedAMMTokenBalance,
            expectedDerivativesTotalBalance,
            expectedOpeningFeeTotalBalance,
            expectedLiquidationDepositFeeTotalBalance,
            expectedPublicationFeeTotalBalance,
            expectedLiquidityPoolTotalBalance,
            expectedTreasuryTotalBalance
        );

        let openerUserTokenBalanceBeforePayout = testUtils.MILTON_10_000_000_USD;
        let closerUserTokenBalanceBeforePayout = testUtils.MILTON_10_000_000_USD;


        const ammTokenBalanceAfterPayout = BigInt(await tokenDai.balanceOf(milton.address));
        const openerUserTokenBalanceAfterPayout = BigInt(await tokenDai.balanceOf(openerUserAddress));
        const closerUserTokenBalanceAfterPayout = BigInt(await tokenDai.balanceOf(closerUserAddress));

        let expectedSumOfBalancesBeforePayout = null;
        let actualSumOfBalances = null;

        if (openerUserAddress === closerUserAddress) {
            expectedSumOfBalancesBeforePayout = ammBalanceBeforePayout + openerUserTokenBalanceBeforePayout;
            actualSumOfBalances = openerUserTokenBalanceAfterPayout + ammTokenBalanceAfterPayout;
        } else {
            expectedSumOfBalancesBeforePayout = ammBalanceBeforePayout + openerUserTokenBalanceBeforePayout + closerUserTokenBalanceBeforePayout;
            actualSumOfBalances = openerUserTokenBalanceAfterPayout + closerUserTokenBalanceAfterPayout + ammTokenBalanceAfterPayout;
        }

        assert(expectedSumOfBalancesBeforePayout === actualSumOfBalances,
            `Incorrect balance between AMM Balance and Users Balance for asset ${asset}, actual: ${actualSumOfBalances}, expected ${expectedSumOfBalancesBeforePayout}`);

    }

    const assertSoap = async (params) => {
        let actualSoapStruct = await calculateSoap(params);
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then
        assert(params.expectedSoap === actualSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`)
    }

    const assertDerivativeItem = function (itemName, expected, actual) {
        assert(actual === expected, `Incorrect ${itemName} ${actual}, expected ${expected}`);
    }
    const assertBalances = async (
        asset,
        openerUserAddress,
        closerUserAddress,
        expectedOpenerUserTokenBalance,
        expectedCloserUserTokenBalance,
        expectedAMMTokenBalance,
        expectedDerivativesTotalBalance,
        expectedOpeningFeeTotalBalance,
        expectedLiquidationDepositFeeTotalBalance,
        expectedPublicationFeeTotalBalance,
        expectedLiquidityPoolTotalBalance,
        expectedTreasuryTotalBalance
    ) => {

        let actualOpenerUserTokenBalance = null;
        let actualCloserUserTokenBalance = null;
        if (asset === "DAI") {
            actualOpenerUserTokenBalance = BigInt(await tokenDai.balanceOf(openerUserAddress));
            actualCloserUserTokenBalance = BigInt(await tokenDai.balanceOf(closerUserAddress));
        }

        let balance = await milton.balances(asset);

        const actualAMMTokenBalance = BigInt(await miltonDevToolDataProvider.getMiltonTotalSupply(asset));
        const actualDerivativesTotalBalance = BigInt(balance.derivatives);
        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidationDepositFeeTotalBalance = BigInt(balance.liquidationDeposit);
        const actualPublicationFeeTotalBalance = BigInt(balance.iporPublicationFee);
        const actualLiquidityPoolTotalBalance = BigInt(balance.liquidityPool);
        const actualTreasuryTotalBalance = BigInt(balance.treasury);

        if (expectedAMMTokenBalance !== null) {
            assert(actualAMMTokenBalance === expectedAMMTokenBalance,
                `Incorrect token balance for ${asset} in AMM address, actual: ${actualAMMTokenBalance}, expected: ${expectedAMMTokenBalance}`);
        }

        if (expectedOpenerUserTokenBalance != null) {
            assert(actualOpenerUserTokenBalance === expectedOpenerUserTokenBalance,
                `Incorrect token balance for ${asset} in Opener User address, actual: ${actualOpenerUserTokenBalance}, expected: ${expectedOpenerUserTokenBalance}`);
        }

        if (expectedCloserUserTokenBalance != null) {
            assert(actualCloserUserTokenBalance === expectedCloserUserTokenBalance,
                `Incorrect token balance for ${asset} in Closer User address, actual: ${actualCloserUserTokenBalance}, expected: ${expectedCloserUserTokenBalance}`);
        }

        if (expectedDerivativesTotalBalance != null) {
            assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
                `Incorrect derivatives total balance for ${asset}, actual:  ${actualDerivativesTotalBalance}, expected: ${expectedDerivativesTotalBalance}`)
        }

        if (expectedOpeningFeeTotalBalance != null) {
            assert(expectedOpeningFeeTotalBalance === actualOpeningFeeTotalBalance,
                `Incorrect opening fee total balance for ${asset}, actual:  ${actualOpeningFeeTotalBalance}, expected: ${expectedOpeningFeeTotalBalance}`)
        }

        if (expectedLiquidationDepositFeeTotalBalance !== null) {
            assert(expectedLiquidationDepositFeeTotalBalance === actualLiquidationDepositFeeTotalBalance,
                `Incorrect liquidation deposit fee total balance for ${asset}, actual:  ${actualLiquidationDepositFeeTotalBalance}, expected: ${expectedLiquidationDepositFeeTotalBalance}`)
        }

        if (expectedPublicationFeeTotalBalance != null) {
            assert(expectedPublicationFeeTotalBalance === actualPublicationFeeTotalBalance,
                `Incorrect ipor publication fee total balance for ${asset}, actual: ${actualPublicationFeeTotalBalance}, expected: ${expectedPublicationFeeTotalBalance}`)
        }

        if (expectedLiquidityPoolTotalBalance != null) {
            assert(expectedLiquidityPoolTotalBalance === actualLiquidityPoolTotalBalance,
                `Incorrect Liquidity Pool total balance for ${asset}, actual:  ${actualLiquidityPoolTotalBalance}, expected: ${expectedLiquidityPoolTotalBalance}`)
        }

        if (expectedTreasuryTotalBalance != null) {
            assert(expectedTreasuryTotalBalance === actualTreasuryTotalBalance,
                `Incorrect Treasury total balance for ${asset}, actual:  ${actualTreasuryTotalBalance}, expected: ${expectedTreasuryTotalBalance}`)
        }
    }
});
