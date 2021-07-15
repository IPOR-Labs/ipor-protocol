const {time} = require("@openzeppelin/test-helpers");
const IporAmmV1 = artifacts.require('IporAmmV1');
const TestIporAmmV1Proxy = artifacts.require('TestIporAmmV1Proxy');
const IporOracle = artifacts.require('IporOracle');
const TestIporOracleProxy = artifacts.require('TestIporOracleProxy');
const IporPool = artifacts.require("IporPool");
const SimpleToken = artifacts.require('SimpleToken');
const DerivativeLogic = artifacts.require('DerivativeLogic');

const PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;
const PERIOD_28_DAYS_IN_SECONDS = 60 * 60 * 24 * 28;
const PERIOD_50_DAYS_IN_SECONDS = 60 * 60 * 24 * 50;
const ZERO = BigInt("0");
const AMM_10_USD = BigInt("10000000000000000000");
const AMM_20_USD = BigInt("20000000000000000000");
const AMM_99__7_USD = BigInt("99700000000000000000")
const AMM_10_000_USD = BigInt("10000000000000000000000");
const AMM_10_400_USD = BigInt("10400000000000000000000");
const AMM_10_000_000_USD = BigInt("10000000000000000000000000");
const AMM_3_PERCENTAGE = BigInt("30000000000000000");
const AMM_5_PERCENTAGE = BigInt("50000000000000000");
const AMM_6_PERCENTAGE = BigInt("60000000000000000");
const AMM_50_PERCENTAGE = BigInt("500000000000000000");
const AMM_120_PERCENTAGE = BigInt("1200000000000000000");
const AMM_160_PERCENTAGE = BigInt("1600000000000000000");
const AMM_365_PERCENTAGE = BigInt("3650000000000000000");

const assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error), `Expected exception with message ${error}`)
        return;
    }
    assert(false);
}

contract('IporAmm', (accounts) => {

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
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporOracle = null;

    before(async () => {
        derivativeLogic = await DerivativeLogic.deployed();
    });

    beforeEach(async () => {

        iporOracle = await TestIporOracleProxy.new();

        //10 000 000 000 000 USD
        tokenUsdt = await SimpleToken.new('Mocked USDT', 'USDT', totalSupply6Decimals, 6);
        //10 000 000 000 000 USD
        tokenUsdc = await SimpleToken.new('Mocked USDC', 'USDC', totalSupply6Decimals, 6);
        //10 000 000 000 000 USD
        tokenDai = await SimpleToken.new('Mocked DAI', 'DAI', totalSupply18Decimals, 18);

        amm = await TestIporAmmV1Proxy.new(iporOracle.address, tokenUsdt.address, tokenUsdc.address, tokenDai.address);

        await iporOracle.addUpdater(userOne);

        for (let i = 1; i < accounts.length - 2; i++) {
            await tokenUsdt.transfer(accounts[i], userSupply6Decimals);
            await tokenUsdc.transfer(accounts[i], userSupply6Decimals);
            await tokenDai.transfer(accounts[i], userSupply18Decimals);

            //AMM has rights to spend money on behalf of user
            await tokenUsdt.approve(amm.address, totalSupply6Decimals, {from: accounts[i]});
            await tokenUsdc.approve(amm.address, totalSupply6Decimals, {from: accounts[i]});
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
            'Reason given: IPOR_4'
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
            'Reason given: IPOR_5'
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
            'Reason given: IPOR_9'
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
            'Reason given: IPOR_10'
        );
    });

    it('should open pay fixed position - simple case DAI', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: AMM_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await iporOracle.updateIndex(params.asset, AMM_3_PERCENTAGE, {from: userOne});

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
            AMM_10_000_USD,
            BigInt("9990000000000000000000000"),
            BigInt("9990000000000000000000000"),
            BigInt("99700000000000000000"),
            1,
            BigInt("9870300000000000000000"),
            AMM_20_USD
        );

        const actualDerivativesTotalBalance = BigInt(await amm.derivativesTotalBalances(params.asset));

        assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
            `Incorrect derivatives total balance for ${params.asset} ${actualDerivativesTotalBalance}, expected ${expectedDerivativesTotalBalance}`)


    });

    it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_3_PERCENTAGE, AMM_3_PERCENTAGE, 0, ZERO,
            BigInt("109700000000000000000"), //expectedAMMTokenBalance
            BigInt("9999890300000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9999890300000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("99700000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_365_PERCENTAGE, AMM_365_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("177304794520547945205"), //expectedAMMTokenBalance
            BigInt("9999822695205479452054795"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9999822695205479452054795"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("167304794520547945205"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
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

        await iporOracle.updateIndex(params.asset, BigInt("10000000000000000"), {from: userOne});
        await openPositionFunc(params);
        await iporOracle.updateIndex(params.asset, BigInt("1600000000000000000"), {from: userOne});
        await time.increase(PERIOD_25_DAYS_IN_SECONDS);
        await iporOracle.updateIndex(params.asset, BigInt("50000000000000000"), {from: userOne});

        //when
        await assertError(
            //when
            amm.closePosition(0, {from: userTwo}),
            //then
            'Reason given: IPOR_14'
        );

    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_160_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_120_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("7951856164383561677638"), //expectedAMMTokenBalance
            BigInt("9992048143835616438322362"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9992048143835616438322362"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("7941856164383561677638"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_120_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("8595453808219178149796"), //expectedAMMTokenBalance
            BigInt("9991404546191780821850204"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9991404546191780821850204"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("8585453808219178149796"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_5_PERCENTAGE, AMM_160_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009760600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10009760600000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_5_PERCENTAGE, AMM_120_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("2802753424657534268208"), //expectedAMMTokenBalance
            BigInt("10007597246575342465731792"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10007597246575342465731792"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2792753424657534268208"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_5_PERCENTAGE, AMM_160_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009760600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10009760600000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });


    it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_5_PERCENTAGE, AMM_50_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("4203524767123287755062"), //expectedAMMTokenBalance
            BigInt("10006196475232876712244938"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10006196475232876712244938"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("4193524767123287755062"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });


    it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userThree,
            AMM_5_PERCENTAGE, AMM_160_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009740600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });


    it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: AMM_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await iporOracle.test_updateIndex(params.asset, AMM_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await iporOracle.test_updateIndex(params.asset, AMM_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await iporOracle.test_updateIndex(params.asset, AMM_6_PERCENTAGE, endTimestamp, {from: userOne});
        await amm.provideLiquidity(params.asset, AMM_10_400_USD, {from: liquidityProvider})

        //when
        await assertError(
            //when
            amm.test_closePosition(0, endTimestamp, {from: userThree}),
            //then
            'Reason given: IPOR_16');
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userThree,
            AMM_5_PERCENTAGE, AMM_160_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009740600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userThree,
            AMM_5_PERCENTAGE, AMM_50_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("4203524767123287755062"), //expectedAMMTokenBalance
            BigInt("10006176475232876712244938"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("4193524767123287755062"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userThree,
            AMM_160_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS,
            ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: AMM_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await iporOracle.test_updateIndex(params.asset, AMM_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await iporOracle.test_updateIndex(params.asset, AMM_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await iporOracle.test_updateIndex(params.asset, AMM_6_PERCENTAGE, endTimestamp, {from: userOne});
        await amm.provideLiquidity(params.asset, AMM_10_400_USD, {from: liquidityProvider})

        //when
        await assertError(
            //when
            amm.test_closePosition(0, endTimestamp, {from: userThree}),
            //then
            'Reason given: IPOR_16');
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userThree,
            AMM_120_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            BigInt("8595453808219178149796"), //expectedAMMTokenBalance
            BigInt("9991384546191780821850204"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("8585453808219178149796"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userThree,
            AMM_160_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS,
            ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_3_PERCENTAGE, AMM_3_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("177304794520547924925"), //expectedAMMTokenBalance
            BigInt("9999822695205479452075075"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9999822695205479452075075"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("167304794520547924925"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });


    it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price changed 25%, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_365_PERCENTAGE, AMM_365_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("177304794520547945206"), //expectedAMMTokenBalance
            BigInt("9999822695205479452054794"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9999822695205479452054794"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("167304794520547945206"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_160_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009760600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10009760600000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_120_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("2802753424657534212773"), //expectedAMMTokenBalance
            BigInt("10007597246575342465787227"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10007597246575342465787227"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2792753424657534212773"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_5_PERCENTAGE, AMM_160_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_5_PERCENTAGE, AMM_120_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("7951856164383561622203"), //expectedAMMTokenBalance
            BigInt("9992048143835616438377797"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9992048143835616438377797"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("7941856164383561622203"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_160_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009760600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10009760600000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });


    it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_120_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("2175380931506849247464"), //expectedAMMTokenBalance
            BigInt("10008224619068493150752536"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10008224619068493150752536"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2165380931506849247464"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_5_PERCENTAGE, AMM_120_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userTwo,
            AMM_5_PERCENTAGE, AMM_50_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("6567309972602739642198"), //expectedAMMTokenBalance
            BigInt("9993432690027397260357802"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9993432690027397260357802"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("6557309972602739642198"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned > Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userThree,
            AMM_160_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009740600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: AMM_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await iporOracle.test_updateIndex(params.asset, AMM_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await iporOracle.test_updateIndex(params.asset, AMM_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await iporOracle.test_updateIndex(params.asset, AMM_6_PERCENTAGE, endTimestamp, {from: userOne});
        await amm.provideLiquidity(params.asset, AMM_10_400_USD, {from: liquidityProvider})

        //when
        await assertError(
            //when
            amm.test_closePosition(0, endTimestamp, {from: userThree}),
            //then
            'Reason given: IPOR_16');
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost > Deposit, before maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userThree,
            AMM_5_PERCENTAGE, AMM_160_PERCENTAGE, PERIOD_25_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        //given
        const params = {
            asset: "DAI",
            totalAmount: AMM_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await iporOracle.test_updateIndex(params.asset, AMM_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await iporOracle.test_updateIndex(params.asset, AMM_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + PERIOD_25_DAYS_IN_SECONDS;
        await iporOracle.test_updateIndex(params.asset, AMM_6_PERCENTAGE, endTimestamp, {from: userOne});

        //when
        await assertError(
            //when
            amm.test_closePosition(0, endTimestamp, {from: userThree}),
            //then
            'Reason given: IPOR_16');
    });
    //----
    it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned > Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userThree,
            AMM_160_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("639400000000000000000"), //expectedAMMTokenBalance
            BigInt("10009740600000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("629400000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userThree,
            AMM_120_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, AMM_10_400_USD,
            BigInt("2175380931506849247464"), //expectedAMMTokenBalance
            BigInt("10008204619068493150752536"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("2165380931506849247464"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userThree,
            AMM_5_PERCENTAGE, AMM_160_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990000000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 1, userTwo, userThree,
            AMM_5_PERCENTAGE, AMM_50_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("6567309972602739642198"), //expectedAMMTokenBalance
            BigInt("9993412690027397260357802"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("10000020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("6557309972602739642198"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost > Deposit, after maturity', async () => {
        await exetuceTestCase(
            "DAI", 10, 0, userTwo, userTwo,
            AMM_160_PERCENTAGE, AMM_5_PERCENTAGE, PERIOD_50_DAYS_IN_SECONDS, ZERO,
            BigInt("9980000000000000000000"), //expectedAMMTokenBalance
            BigInt("9990020000000000000000000"), //expectedOpenerUserTokenBalanceAfterPayOut
            BigInt("9990020000000000000000000"), //expectedCloserUserTokenBalanceAfterPayOut
            BigInt("9970000000000000000000"), //expectedLiquidityPoolTotalBalance
            0, ZERO, ZERO
        );
    });

    //TODO: test when ipor not ready yet
    //TODO: check initial IBT
    //TODO: create test when ipor index not yet created for specific asset

    //TODO: test na 1 sprwdzenie czy totalAmount wiekszy od fee
    //TODO: test na 2 sprwdzenie czy totalAmount wiekszy od fee (po przeliczeniu openingFeeAmount)
    //TODO: test na wysłanie USDT które ma 6 miejsc po przecinku i weryfikacja liczb

    //TODO: test close position - check if sender who closed has liquidation deposit in DAI token.
    //
    //TODO: verify if sender can close derivative
    //TODO: owner moze zamknąc zawsze, ktokolwiek moze zamknąc gdy: minęło 28 dni (maturity), gdy jest poza zakresem +- 100%
    //TODO: liquidation deposit trafia do osoby która wykona zamknięcie depozytu

    const openPositionFunc = async (params) => {
        await amm.test_openPosition(params.openTimestamp, params.asset, params.totalAmount, params.slippageValue, params.leverage, params.direction, {from: params.from});
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
    const exetuceTestCase = async function (
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
        expectedLiquidationDepositFeeTotalBalance
    ) {
        //given
        const params = {
            asset: "DAI",
            totalAmount: AMM_10_000_USD,
            slippageValue: 3,
            leverage: 10,
            direction: direction,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: openerUserAddress
        }

        await iporOracle.test_updateIndex(params.asset, iporValueBeforOpenPosition, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await iporOracle.test_updateIndex(params.asset, iporValueAfterOpenPosition, params.openTimestamp, {from: userOne});

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;
        await iporOracle.test_updateIndex(params.asset, AMM_6_PERCENTAGE, endTimestamp, {from: userOne});

        if (providedLiquidityAmount != null) {
            await amm.provideLiquidity(params.asset, providedLiquidityAmount, {from: liquidityProvider})
        }

        //when
        await amm.test_closePosition(0, endTimestamp, {from: closerUserAddress});

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
        assert(expectedOpenedPositions === actualOpenPositionsVol, `Incorrect number of opened derivatives ${actualOpenPositionsVol}, expected 0`)

        let expectedOpeningFeeTotalBalance = AMM_99__7_USD;
        let expectedPublicationFeeTotalBalance = AMM_10_USD;

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

        let openerUserTokenBalanceBeforePayout = AMM_10_000_000_USD;
        let closerUserTokenBalanceBeforePayout = AMM_10_000_000_USD;


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