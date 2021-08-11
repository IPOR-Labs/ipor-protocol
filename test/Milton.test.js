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
const PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;
const PERIOD_28_DAYS_IN_SECONDS = 60 * 60 * 24 * 28;
const PERIOD_50_DAYS_IN_SECONDS = 60 * 60 * 24 * 50;
const ZERO = BigInt("0");
const MILTON_10_USD = BigInt("10000000000000000000");
const MILTON_20_USD = BigInt("20000000000000000000");
const MILTON_99__7_USD = BigInt("99700000000000000000")
const MILTON_10_000_USD = BigInt("10000000000000000000000");
const MILTON_10_400_USD = BigInt("10400000000000000000000");
const MILTON_10_000_000_USD = BigInt("10000000000000000000000000");
const MILTON_3_PERCENTAGE = BigInt("30000000000000000");
const MILTON_5_PERCENTAGE = BigInt("50000000000000000");
const MILTON_6_PERCENTAGE = BigInt("60000000000000000");
const MILTON_50_PERCENTAGE = BigInt("500000000000000000");
const MILTON_120_PERCENTAGE = BigInt("1200000000000000000");
const MILTON_160_PERCENTAGE = BigInt("1600000000000000000");
const MILTON_365_PERCENTAGE = BigInt("3650000000000000000");

const assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error), `Expected exception with message ${error} but actual error message: ${e.message}`)
        return;
    }
    assert(false);
}

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

    let amm = null;
    let derivativeLogic = null;
    let soapIndicatorLogic = null;
    let totalSoapIndicatorLogic = null;
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let warren = null;
    let miltonConfiguration = null;

    before(async () => {
        derivativeLogic = await DerivativeLogic.deployed();
        soapIndicatorLogic = await SoapIndicatorLogic.deployed();
        totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deployed();
        miltonConfiguration = await MiltonConfiguration.deployed();
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

        amm = await TestMiltonV1Proxy.new(
            miltonConfiguration.address,
            warren.address, tokenUsdt.address, tokenUsdc.address, tokenDai.address);

        await warren.addUpdater(userOne);

        for (let i = 1; i < accounts.length - 2; i++) {
            await tokenUsdt.transfer(accounts[i], userSupply6Decimals);
            //TODO: zrobic obsługę 6 miejsc po przecinku! - userSupply18Decimals
            await tokenUsdc.transfer(accounts[i], userSupply18Decimals);
            await tokenDai.transfer(accounts[i], userSupply18Decimals);

            //AMM has rights to spend money on behalf of user
            await tokenUsdt.approve(amm.address, totalSupply6Decimals, {from: accounts[i]});
            //TODO: zrobic obsługę 6 miejsc po przecinku! - totalSupply6Decimals
            await tokenUsdc.approve(amm.address, totalSupply18Decimals, {from: accounts[i]});
            await tokenDai.approve(amm.address, totalSupply18Decimals, {from: accounts[i]});
        }

    });

    it('should NOT open position because deposit amount too low', async () => {
        //given
        let asset = "DAI";
        let depositAmount = 0;
        let slippageValue = 3;
        let direction = 0;
        let leverage = 10;

        await assertError(
            //when
            amm.openPosition(asset, depositAmount, slippageValue, leverage, direction),
            //then
            'IPOR_4'
        );
    });


    it('should NOT open position because slippage too low', async () => {
        //given
        let asset = "DAI";
        let depositAmount = BigInt("30000000000000000001");
        let slippageValue = 0;
        let direction = 0;
        let leverage = 10;

        await assertError(
            //when
            amm.openPosition(asset, depositAmount, slippageValue, leverage, direction),
            //then
            'IPOR_5'
        );
    });

    it('should NOT open position because slippage too high', async () => {
        //given
        let asset = "DAI";
        let depositAmount = BigInt("30000000000000000001");
        let slippageValue = web3.utils.toBN(1e20);
        let theOne = web3.utils.toBN(1);
        slippageValue = slippageValue.add(theOne);
        let direction = 0;
        let leverage = 10;

        await assertError(
            //when
            amm.openPosition(asset, depositAmount, slippageValue, leverage, direction),
            //then
            'IPOR_9'
        );
    });

    it('should NOT open position because deposit amount too high', async () => {
        //given
        let asset = "DAI";
        let depositAmount = BigInt("1000000000000000000000001")
        let slippageValue = 3;
        let direction = 0;
        let leverage = 10;

        await assertError(
            //when
            amm.openPosition(asset, depositAmount, slippageValue, leverage, direction),
            //then
            'IPOR_10'
        );
    });

    it('should open pay fixed position - simple case DAI', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await warren.updateIndex(params.asset, MILTON_3_PERCENTAGE, {from: userOne});

        //when
        await amm.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.leverage,
            params.direction, {from: userTwo});

        //then
        const expectedDerivativesTotalBalance = BigInt("9870300000000000000000");

        await assertExpectedValues(
            params.asset,
            userTwo,
            userTwo,
            ZERO,
            MILTON_10_000_USD,
            BigInt("9990000000000000000000000"),
            BigInt("9990000000000000000000000"),
            BigInt("99700000000000000000"),
            1,
            BigInt("9870300000000000000000"),
            MILTON_20_USD,
            BigInt("0")
        );

        const actualDerivativesTotalBalance = BigInt(await amm.derivativesTotalBalances(params.asset));

        assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
            `Incorrect derivatives total balance for ${params.asset} ${actualDerivativesTotalBalance}, expected ${expectedDerivativesTotalBalance}`)

    });

    // TODO: implement it
    // it('should open receive fixed position - simple case DAI', async () => {
    //
    // });

    it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_3_PERCENTAGE, MILTON_3_PERCENTAGE, 0, ZERO,
            BigInt("109700000000000000000"), //expectedAMMTokenBalance
            BigInt("9999890300000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9999890300000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("99700000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_365_PERCENTAGE, MILTON_365_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("177304794520547945205"), //expectedAMMTokenBalance
            BigInt("9999822695205479452054795"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9999822695205479452054795"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("167304794520547945205"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should NOT open position because Liquidity Pool is to low', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: BigInt("10000000000000000000000"), //10 000 USD
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        let closePositionTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS

        await warren.test_updateIndex(params.asset, BigInt("10000000000000000"), params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await warren.test_updateIndex(params.asset, BigInt("1600000000000000000"), params.openTimestamp, {from: userOne});
        await warren.test_updateIndex(params.asset, BigInt("50000000000000000"), closePositionTimestamp, {from: userOne});

        //when
        await assertError(
            //when
            amm.test_closePosition(1, closePositionTimestamp, {from: userTwo}),
            //then
            'IPOR_14'
        );

    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_160_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_120_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("7951856164383561677638"), //expectedAMMTokenBalance
            BigInt("9992048143835616438322362"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9992048143835616438322362"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("7941856164383561677638"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_120_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("8595453808219178149796"), //expectedAMMTokenBalance
            BigInt("9991404546191780821850204"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9991404546191780821850204"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("8585453808219178149796"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_5_PERCENTAGE, MILTON_160_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009760600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10009760600000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_5_PERCENTAGE, MILTON_120_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("2802753424657534268209"), //expectedAMMTokenBalance
            BigInt("10007597246575342465731791"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10007597246575342465731791"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2792753424657534268209"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_5_PERCENTAGE, MILTON_160_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009760600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10009760600000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });


    it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_5_PERCENTAGE, MILTON_50_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("4203524767123287755062"), //expectedAMMTokenBalance
            BigInt("10006196475232876712244938"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10006196475232876712244938"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("4193524767123287755062"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });


    it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userThree,
            MILTON_5_PERCENTAGE, MILTON_160_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009740600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });


    it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await warren.test_updateIndex(params.asset, MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await warren.test_updateIndex(params.asset, MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await warren.test_updateIndex(params.asset, MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});
        await amm.provideLiquidity(params.asset, MILTON_10_400_USD, {from: liquidityProvider})

        //when
        await assertError(
            //when
            amm.test_closePosition(1, endTimestamp, {from: userThree}),
            //then
            'IPOR_16');
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userThree,
            MILTON_5_PERCENTAGE, MILTON_160_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009740600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userThree,
            MILTON_5_PERCENTAGE, MILTON_50_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("4203524767123287755062"), //expectedAMMTokenBalance
            BigInt("10006176475232876712244938"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("4193524767123287755062"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userThree,
            MILTON_160_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await warren.test_updateIndex(params.asset, MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await warren.test_updateIndex(params.asset, MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await warren.test_updateIndex(params.asset, MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});
        await amm.provideLiquidity(params.asset, MILTON_10_400_USD, {from: liquidityProvider})

        //when
        await assertError(
            //when
            amm.test_closePosition(1, endTimestamp, {from: userThree}),
            //then
            'IPOR_16');
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userThree,
            MILTON_120_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            BigInt("8595453808219178149796"), //expectedAMMTokenBalance
            BigInt("9991384546191780821850204"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("8585453808219178149796"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userThree,
            MILTON_160_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_3_PERCENTAGE, MILTON_3_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("177304794520547924924"), //expectedAMMTokenBalance
            BigInt("9999822695205479452075076"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9999822695205479452075076"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("167304794520547924924"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });


    it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price changed 25%, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_365_PERCENTAGE, MILTON_365_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("177304794520547945205"), //expectedAMMTokenBalance
            BigInt("9999822695205479452054795"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9999822695205479452054795"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("167304794520547945205"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_160_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009760600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10009760600000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_120_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("2802753424657534212773"), //expectedAMMTokenBalance
            BigInt("10007597246575342465787227"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10007597246575342465787227"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2792753424657534212773"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_5_PERCENTAGE, MILTON_160_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_5_PERCENTAGE, MILTON_120_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("7951856164383561622202"), //expectedAMMTokenBalance
            BigInt("9992048143835616438377798"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9992048143835616438377798"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("7951856164383561622202"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_160_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009760600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10009760600000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });


    it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_120_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("2175380931506849247464"), //expectedAMMTokenBalance
            BigInt("10008224619068493150752536"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10008224619068493150752536"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2165380931506849247464"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_5_PERCENTAGE, MILTON_120_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            MILTON_5_PERCENTAGE, MILTON_50_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("6567309972602739642198"), //expectedAMMTokenBalance
            BigInt("9993432690027397260357802"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9993432690027397260357802"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("6557309972602739642198"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userThree,
            MILTON_160_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009740600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await warren.test_updateIndex(params.asset, MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await warren.test_updateIndex(params.asset, MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await warren.test_updateIndex(params.asset, MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});
        await amm.provideLiquidity(params.asset, MILTON_10_400_USD, {from: liquidityProvider})

        //when
        await assertError(
            //when
            amm.test_closePosition(1, endTimestamp, {from: userThree}),
            //then
            'IPOR_16');
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userThree,
            MILTON_5_PERCENTAGE, MILTON_160_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await warren.test_updateIndex(params.asset, MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await warren.test_updateIndex(params.asset, MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await warren.test_updateIndex(params.asset, MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});

        //when
        await assertError(
            //when
            amm.test_closePosition(1, endTimestamp, {from: userThree}),
            //then
            'IPOR_16');
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userThree,
            MILTON_160_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009740600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userThree,
            MILTON_120_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, MILTON_10_400_USD,
            BigInt("2175380931506849247464"), //expectedAMMTokenBalance
            BigInt("10008204619068493150752536"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2165380931506849247464"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userThree,
            MILTON_5_PERCENTAGE, MILTON_160_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 1, userTwo, userThree,
            MILTON_5_PERCENTAGE, MILTON_50_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("6567309972602739642198"), //expectedAMMTokenBalance
            BigInt("9993412690027397260357802"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("6557309972602739642198"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
        await exetuceClosePositionTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            MILTON_160_PERCENTAGE, MILTON_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO,
            ZERO
        );
    });

    it('should calculate soap, no derivatives, soap equal 0', async () => {
        //given
        const params = {
            asset: "DAI",
            calculateTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        let expectedSoap = ZERO;

        //when
        let actualSoapStruct = await calculateSoap(params)
        let actualSoap = BigInt(actualSoapStruct.soap);

        //then

        assert(expectedSoap === actualSoap,
            `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${expectedSoap}`)
    });

    it('should calculate soap, DAI, pay fixed, add position, calculate now', async () => {

        //given
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_5_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = ZERO;

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
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = BigInt("-270419178082191780822");

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI, rec fixed, add position, calculate now', async () => {
        //given
        let direction = 1;
        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = ZERO;

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
        let direction = 1;
        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = BigInt("135209589041095890411");

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI, pay fixed, add and remove position', async () => {
        // given
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let endTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await amm.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        let expectedSoap = ZERO;

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: endTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI, rec fixed, add and remove position', async () => {
        //given
        let direction = 1;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);

        let expectedSoap = ZERO;
        let endTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //we expecting that Milton loose his money, so we add some cash to liquidity pool
        await amm.provideLiquidity(derivativeParams.asset, MILTON_10_000_USD, {from: liquidityProvider})

        //when
        await amm.test_closePosition(1, endTimestamp, {from: closerUserAddress});


        const soapParams = {
            asset: "DAI",
            calculateTimestamp: derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed', async () => {
        //given
        let firstDerivativeDirection = 0;
        let secondDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const firstDerivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: firstDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const secondDerivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: secondDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await warren.test_updateIndex(firstDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(firstDerivativeParams);
        await openPositionFunc(secondDerivativeParams);

        let expectedSoap = BigInt("-135209589041095890411");

        //when
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, USDC add pay fixed', async () => {
        //given
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeDAIParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const derivativeUSDCParams = {
            asset: "USDC",
            totalAmount: MILTON_10_000_USD,
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
        let expectedDAISoap = BigInt("-270419178082191780822");
        //TODO: poprawic gdy zmiana na 6 miejsc po przecinku (zmiany w całym kodzie)
        let expectedUSDCSoap = BigInt("-270419178082191780822");

        const soapDAIParams = {
            asset: "DAI",
            calculateTimestamp: derivativeDAIParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedDAISoap,
            from: userTwo
        }
        await assertSoap(soapDAIParams);

        const soapUSDCParams = {
            asset: "USDC",
            calculateTimestamp: derivativeUSDCParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedUSDCSoap,
            from: userTwo
        }
        await assertSoap(soapUSDCParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed, close rec fixed position', async () => {
        //given
        let payFixDerivativeDirection = 0;
        let recFixDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: payFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: recFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await warren.test_updateIndex(payFixDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(payFixDerivativeParams);
        await openPositionFunc(recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await amm.test_closePosition(2, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoap = BigInt("-270419178082191780822");

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, DAI add rec fixed, remove pay fixed position after 25 days', async () => {
        //given
        let payFixDerivativeDirection = 0;
        let recFixDerivativeDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: payFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: recFixDerivativeDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        await warren.test_updateIndex(payFixDerivativeParams.asset, iporValueBeforOpenPosition, openTimestamp, {from: userOne});
        await openPositionFunc(payFixDerivativeParams);
        await openPositionFunc(recFixDerivativeParams);

        let endTimestamp = recFixDerivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await amm.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoap = BigInt("135209589041095890411");

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });


    it('should calculate soap, DAI add pay fixed, USDC add rec fixed, remove DAI rec fixed position after 25 days', async () => {
        //given
        let payFixDerivativeDAIDirection = 0;
        let recFixDerivativeUSDCDirection = 1;

        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const payFixDerivativeDAIParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: payFixDerivativeDAIDirection,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        const recFixDerivativeUSDCParams = {
            asset: "USDC",
            totalAmount: MILTON_10_000_USD,
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
        await amm.provideLiquidity(recFixDerivativeUSDCParams.asset, MILTON_10_000_USD, {from: liquidityProvider})

        let endTimestamp = recFixDerivativeUSDCParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        //when
        await amm.test_closePosition(2, endTimestamp, {from: closerUserAddress});

        //then
        let expectedSoap = BigInt("-270419178082191780822");

        const soapParams = {
            asset: "DAI",
            calculateTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            expectedSoap: expectedSoap,
            from: userTwo
        }

        await assertSoap(soapParams);
    });

    it('should calculate soap, DAI add pay fixed, change ibtPrice, wait 25 days and then calculate soap', async () => {
        //given
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let iporValueAfterOpenPosition = MILTON_120_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);
        await warren.test_updateIndex(derivativeParams.asset, iporValueAfterOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await warren.test_updateIndex(derivativeParams.asset, MILTON_6_PERCENTAGE, calculationTimestamp, {from: userOne});

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
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let iporValueAfterOpenPosition = MILTON_120_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }

        let calculationTimestamp25days = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        let calculationTimestamp28days = derivativeParams.openTimestamp + PERIOD_28_DAYS_IN_SECONDS;
        let calculationTimestamp50days = derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS;

        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParams);
        await warren.test_updateIndex(derivativeParams.asset, iporValueAfterOpenPosition, derivativeParams.openTimestamp, {from: userOne});
        await warren.test_updateIndex(derivativeParams.asset, MILTON_6_PERCENTAGE, calculationTimestamp25days, {from: userOne});

        let expectedSoap28Days = BigInt("7809705863013698608503");
        let expectedSoap50Days = BigInt("7571736986301369841380");

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
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        await openPositionFunc(derivativeParams25days);

        let calculationTimestamp50days = derivativeParams25days.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        let expectedSoap = BigInt("-811257534246575342466");

        //when
        //then
        const soapParams = {
            asset: "DAI",
            calculateTimestamp: calculationTimestamp50days,
            expectedSoap: expectedSoap,
            from: userTwo
        }
        await assertSoap(soapParams);

    });

    it('should NOT close position, because incorrect derivative Id', async () => {
        //given
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        await assertError(
            //when
            amm.test_closePosition(0, openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: closerUserAddress}),
            //then
            'IPOR_22'
        );
    });

    it('should NOT close position, because derivative has incorrect status', async () => {
        //given
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        await openPositionFunc(derivativeParams25days);

        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS

        await amm.test_closePosition(1, endTimestamp, {from: closerUserAddress})

        await assertError(
            //when
            amm.test_closePosition(1, endTimestamp, {from: closerUserAddress}),
            //then
            'IPOR_23'
        );
    });


    it('should close only one position - close first position', async () => {
        //given
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        await openPositionFunc(derivativeParams25days);
        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(2);

        //when
        await amm.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        //then
        let actualDerivatives = await amm.getPositions();
        let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);

        assert(expectedOpenedPositionsVol === actualOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`)

        let oneDerivative = actualDerivatives[0];

        assert(expectedDerivativeId === BigInt(oneDerivative.id),
            `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`)
    });

    it('should close only one position - close last position', async () => {
        //given
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp + PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        await openPositionFunc(derivativeParams25days);
        let endTimestamp = openTimestamp + PERIOD_50_DAYS_IN_SECONDS
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(1);

        //when
        await amm.test_closePosition(2, endTimestamp, {from: closerUserAddress});

        //then
        let actualDerivatives = await amm.getPositions();
        let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);

        assert(expectedOpenedPositionsVol === actualOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`)

        let oneDerivative = actualDerivatives[0];

        assert(expectedDerivativeId === BigInt(oneDerivative.id),
            `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`)

    });

    it('should open many positions and arrays with ids have correct state, one user', async () => {
        //given
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLength = 3
        let expectedDerivativeIdsLength = 3;

        //when
        await openPositionFunc(derivativeParams);
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);


        //then
        let actualUserDerivativeIds = await amm.getUserDerivativeIds(openerUserAddress);
        let actualDerivativeIds = await amm.getDerivativeIds();


        assert(expectedUserDerivativeIdsLength === actualUserDerivativeIds.length,
            `Incorrect user derivative ids length actual: ${actualUserDerivativeIds.length}, expected: ${expectedUserDerivativeIdsLength}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)

        await assertMiltonDerivativeItem(1, 0, 0);
        await assertMiltonDerivativeItem(2, 1, 1);
        await assertMiltonDerivativeItem(3, 2, 2);
    });

    it('should open many positions and arrays with ids have correct state, two users', async () => {
        //given
        let direction = 0;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo
        }
        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 1;
        let expectedDerivativeIdsLength = 3;

        //when
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //then
        let actualUserDerivativeIdsFirst = await amm.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await amm.getUserDerivativeIds(userThree);
        let actualDerivativeIds = await amm.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)

        await assertMiltonDerivativeItem(1, 0, 0);
        await assertMiltonDerivativeItem(2, 1, 0);
        await assertMiltonDerivativeItem(3, 2, 1);

    });

    it('should open many positions and close one position and arrays with ids have correct state, two users', async () => {
        //given
        let direction = 0;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo
        }
        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 2;

        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //when
        await amm.test_closePosition(2, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: userThree});

        //then
        let actualUserDerivativeIdsFirst = await amm.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await amm.getUserDerivativeIds(userThree);
        let actualDerivativeIds = await amm.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)

        await assertMiltonDerivativeItem(1, 0, 0);
        await assertMiltonDerivativeItem(3, 1, 1);
    });

    it('should open many positions and close two positions and arrays with ids have correct state, two users', async () => {
        //given
        let direction = 0;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo
        }
        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 1;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 1;

        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //when
        await amm.test_closePosition(2, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
        await amm.test_closePosition(3, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: userTwo});

        //then
        let actualUserDerivativeIdsFirst = await amm.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await amm.getUserDerivativeIds(userThree);
        let actualDerivativeIds = await amm.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)

        await assertMiltonDerivativeItem(1, 0, 0);

    });

    it('should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1', async () => {
        //given
        let direction = 0;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree
        }
        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);

        //when
        await amm.test_closePosition(1, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
        await amm.test_closePosition(2, derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS, {from: userThree});


        //then
        let actualUserDerivativeIdsFirst = await amm.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await amm.getUserDerivativeIds(userTwo);
        let actualDerivativeIds = await amm.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)


    });

    it('should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1 with minus 3', async () => {
        //given
        let direction = 0;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree
        }
        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS-3;
        await openPositionFunc(derivativeParams);

        //when
        await amm.test_closePosition(1, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
        await amm.test_closePosition(2, derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS, {from: userThree});


        //then
        let actualUserDerivativeIdsFirst = await amm.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await amm.getUserDerivativeIds(userTwo);
        let actualDerivativeIds = await amm.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)


    });

    it('should open two positions and close two positions - Arithmetic overflow - last byte difference - case 1', async () => {
        //given
        let direction = 0;
        let iporValueBeforeOpenPosition = MILTON_3_PERCENTAGE;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree
        }
        await warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        derivativeParams.from = userThree;
        derivativeParams.direction = 0;
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        derivativeParams.direction = 0;
        await openPositionFunc(derivativeParams);

        await amm.test_closePosition(1, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: userThree});

        // //position 3, user first
        // derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        // derivativeParams.from = userTwo;
        // derivativeParams.direction = 1;
        // await openPositionFunc(derivativeParams);
        //
        // //position 4, user first
        // derivativeParams.openTimestamp = derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        // derivativeParams.from = userTwo;
        // derivativeParams.direction = 1;
        // await openPositionFunc(derivativeParams);

        //when
        // await amm.test_closePosition(3, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: userTwo});
        // await amm.test_closePosition(4, derivativeParams.openTimestamp + PERIOD_25_DAYS_IN_SECONDS, {from: userTwo});
        await amm.test_closePosition(2, derivativeParams.openTimestamp + PERIOD_50_DAYS_IN_SECONDS, {from: userThree});


        //then
        let actualUserDerivativeIdsFirst = await amm.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await amm.getUserDerivativeIds(userTwo);
        let actualDerivativeIds = await amm.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)


    });

    //TODO: dodac test 1 otwarta long, zmiana indeksu, 2 otwarta short, zmiana indeksu, zamykamy 1 i 2, soap = 0

    //TODO: dodać test w którym zmieniamy konfiguracje w MiltonConfiguration i widac zmiany w Milton

    //TODO: !!! dodaj testy do MiltonConfiguration


    //TODO: testy na strukturze MiltonDerivatives
    //TODO: dopisac test probujacy zamykac pozycje ktora nie istnieje

    //TODO: napisac test który sprawdza czy SoapIndicator podczas inicjalnego uruchomienia hypotheticalInterestCumulative jest równe zero

    //TODO: test when ipor not ready yet
    //TODO: check initial IBT
    //TODO: create test when ipor index not yet created for specific asset

    //TODO: test na 1 sprwdzenie czy totalAmount wiekszy od fee
    //TODO: test na 2 sprwdzenie czy totalAmount wiekszy od fee (po przeliczeniu openingFeeAmount)
    //TODO: test na wysłanie USDT które ma 6 miejsc po przecinku i weryfikacja liczb


    //TODO: sprawdz w JS czy otworzenie nowej PIERWSZEJ derywatywy poprawnie wylicza SoapIndicator, hypotheticalInterestCumulative powinno być nadal zero
    //TODO: sprawdz w JS czy otworzenej KOLEJNEJ derywatywy poprawnie wylicza SoapIndicator

    const calculateSoap = async (params) => {
        return await amm.test_calculateSoap.call(params.asset, params.calculateTimestamp, {from: params.from});
    }

    const openPositionFunc = async (params) => {
        await amm.test_openPosition(
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
        let actualDerivativeItem = await amm.getDerivativeItem(derivativeId);
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

        let actualDerivative = await amm.getOpenPosition(derivativeId);

        assertDerivativeItem('ID', expectedDerivative.id, actualDerivative.id);
        assertDerivativeItem('State', expectedDerivative.state, actualDerivative.state);
        assertDerivativeItem('Buyer', expectedDerivative.buyer, actualDerivative.buyer);
        assertDerivativeItem('Asset', expectedDerivative.asset, actualDerivative.asset);
        assertDerivativeItem('Direction', expectedDerivative.direction, actualDerivative.direction);
        assertDerivativeItem('Deposit Amount', expectedDerivative.depositAmount, actualDerivative.depositAmount);
        assertDerivativeItem('Liquidation Deposit Amount', expectedDerivative.fee.liquidationDepositAmount, actualDerivative.fee.liquidationDepositAmount);
        assertDerivativeItem('Opening Amount Fee', expectedDerivative.fee.openingAmount, actualDerivative.fee.openingAmount);
        assertDerivativeItem('IPOR Publication Amount Fee', expectedDerivative.fee.iporPublicationAmount, actualDerivative.fee.iporPublicationAmount);
        assertDerivativeItem('Spread Percentage Fee', expectedDerivative.fee.spreadPercentage, actualDerivative.fee.spreadPercentage);
        assertDerivativeItem('Leverage', expectedDerivative.leverage, actualDerivative.leverage);
        assertDerivativeItem('Notional Amount', expectedDerivative.notionalAmount, actualDerivative.notionalAmount);
        // assertDerivativeItem('Derivative starting timestamp', expectedDerivative.startingTimestamp, actualDerivative.startingTimestamp);
        // assertDerivativeItem('Derivative ending timestamp', expectedDerivative.endingTimestamp, actualDerivative.endingTimestamp);
        assertDerivativeItem('IPOR Index Value', expectedDerivative.indicator.iporIndexValue, actualDerivative.indicator.iporIndexValue);
        assertDerivativeItem('IBT Price', expectedDerivative.indicator.ibtPrice, actualDerivative.indicator.ibtPrice);
        assertDerivativeItem('IBT Quantity', expectedDerivative.indicator.ibtQuantity, actualDerivative.indicator.ibtQuantity);
        assertDerivativeItem('Fixed Interest Rate', expectedDerivative.indicator.fixedInterestRate, actualDerivative.indicator.fixedInterestRate);
        assertDerivativeItem('SOAP', expectedDerivative.indicator.soap, actualDerivative.indicator.soap);

    }

    const exetuceClosePositionTestCase = async function (
        asset,
        leverage,
        direction,
        openerUserAddress,
        closerUserAddress,
        iporValueBeforOpenPosition,
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
        expectedSoap
    ) {
        //given
        const params = {
            asset: "DAI",
            totalAmount: MILTON_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await warren.test_updateIndex(params.asset, iporValueBeforOpenPosition, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await warren.test_updateIndex(params.asset, iporValueAfterOpenPosition, params.openTimestamp, {from: userOne});

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;
        await warren.test_updateIndex(params.asset, MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});

        if (providedLiquidityAmount != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await amm.provideLiquidity(params.asset, providedLiquidityAmount, {from: liquidityProvider})
        }

        //when
        await amm.test_closePosition(1, endTimestamp, {from: closerUserAddress});

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
            expectedLiquidationDepositFeeTotalBalance
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
        expectedLiquidationDepositFeeTotalBalance
    ) {
        let actualDerivatives = await amm.getPositions();
        let actualOpenPositionsVol = countOpenPositions(actualDerivatives);
        assert(expectedOpenedPositions === actualOpenPositionsVol,
            `Incorrect number of opened derivatives ${actualOpenPositionsVol}, expected ${expectedOpenedPositions}`)

        let expectedOpeningFeeTotalBalance = MILTON_99__7_USD;
        let expectedPublicationFeeTotalBalance = MILTON_10_USD;

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
            expectedLiquidityPoolTotalBalance
        );

        let openerUserTokenBalanceBeforePayout = MILTON_10_000_000_USD;
        let closerUserTokenBalanceBeforePayout = MILTON_10_000_000_USD;


        const ammTokenBalanceAfterPayout = BigInt(await tokenDai.balanceOf(amm.address));
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
            `Incorrect balance between AMM Balance and Users Balance for asset ${asset}, ${actualSumOfBalances}, expected ${expectedSumOfBalancesBeforePayout}`);

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
        expectedLiquidityPoolTotalBalance
    ) => {

        let actualOpenerUserTokenBalance = null;
        let actualCloserUserTokenBalance = null;
        if (asset === "DAI") {
            actualOpenerUserTokenBalance = BigInt(await tokenDai.balanceOf(openerUserAddress));
            actualCloserUserTokenBalance = BigInt(await tokenDai.balanceOf(closerUserAddress));
        }

        const actualAMMTokenBalance = BigInt(await amm.getTotalSupply(asset));
        const actualDerivativesTotalBalance = BigInt(await amm.derivativesTotalBalances(asset));
        const actualOpeningFeeTotalBalance = BigInt(await amm.openingFeeTotalBalances(asset));
        const actualLiquidationDepositFeeTotalBalance = BigInt(await amm.liquidationDepositTotalBalances(asset));
        const actualPublicationFeeTotalBalance = BigInt(await amm.iporPublicationFeeTotalBalances(asset));
        const actualLiquidityPoolTotalBalance = BigInt(await amm.liquidityPoolTotalBalances(asset));

        if (expectedAMMTokenBalance !== null) {
            assert(actualAMMTokenBalance === expectedAMMTokenBalance,
                `Incorrect token balance for ${asset} in AMM address ${actualAMMTokenBalance}, expected ${expectedAMMTokenBalance}`);
        }

        if (expectedOpenerUserTokenBalance != null) {
            assert(actualOpenerUserTokenBalance === expectedOpenerUserTokenBalance,
                `Incorrect token balance for ${asset} in Opener User address ${actualOpenerUserTokenBalance}, expected ${expectedOpenerUserTokenBalance}`);
        }

        if (expectedCloserUserTokenBalance != null) {
            assert(actualCloserUserTokenBalance === expectedCloserUserTokenBalance,
                `Incorrect token balance for ${asset} in Closer User address ${actualCloserUserTokenBalance}, expected ${expectedCloserUserTokenBalance}`);
        }

        if (expectedDerivativesTotalBalance != null) {
            assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
                `Incorrect derivatives total balance for ${asset} ${actualDerivativesTotalBalance}, expected ${expectedDerivativesTotalBalance}`)
        }

        if (expectedOpeningFeeTotalBalance != null) {
            assert(expectedOpeningFeeTotalBalance === actualOpeningFeeTotalBalance,
                `Incorrect opening fee total balance for ${asset} ${actualOpeningFeeTotalBalance}, expected ${expectedOpeningFeeTotalBalance}`)
        }

        if (expectedLiquidationDepositFeeTotalBalance !== null) {
            assert(expectedLiquidationDepositFeeTotalBalance === actualLiquidationDepositFeeTotalBalance,
                `Incorrect liquidation deposit fee total balance for ${asset} ${actualLiquidationDepositFeeTotalBalance}, expected ${expectedLiquidationDepositFeeTotalBalance}`)
        }

        if (expectedPublicationFeeTotalBalance != null) {
            assert(expectedPublicationFeeTotalBalance === actualPublicationFeeTotalBalance,
                `Incorrect ipor publication fee total balance for ${asset} ${actualPublicationFeeTotalBalance}, expected ${expectedPublicationFeeTotalBalance}`)
        }

        if (expectedLiquidityPoolTotalBalance != null) {
            assert(expectedLiquidityPoolTotalBalance === actualLiquidityPoolTotalBalance,
                `Incorrect Liquidity Pool total balance for ${asset} ${actualLiquidityPoolTotalBalance}, expected ${expectedLiquidityPoolTotalBalance}`)
        }
    }
});