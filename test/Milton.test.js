const keccak256 = require('keccak256')
const testUtils = require("./TestUtils.js");
const {ZERO} = require("./TestUtils");

contract('Milton', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let data = null;
    let testData = null;

    before(async () => {
        data = await testUtils.prepareDataForBefore(accounts);
    });

    beforeEach(async () => {
        testData = await testUtils.prepareDataForBeforeEach(data);
    });

    it('should NOT open position because deposit amount too low', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let asset = data.tokenDai.address;
        let collateral = 0;
        let slippageValue = 3;
        let direction = 0;
        let collateralizationFactor = testUtils.MILTON_10_USD;

        await testUtils.assertError(
            //when
            data.milton.openPosition(asset, collateral, slippageValue, collateralizationFactor, direction),
            //then
            'IPOR_4'
        );
    });

    it('should NOT open position because slippage too low', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let asset = data.tokenDai.address;
        let collateral = BigInt("30000000000000000001");
        let slippageValue = 0;
        let direction = 0;
        let collateralizationFactor = testUtils.MILTON_10_USD;

        await testUtils.assertError(
            //when
            data.milton.openPosition(asset, collateral, slippageValue, collateralizationFactor, direction),
            //then
            'IPOR_5'
        );
    });

    it('should NOT open position because slippage too high', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let asset = data.tokenDai.address;
        let collateral = BigInt("30000000000000000001");
        let slippageValue = web3.utils.toBN(1e20);
        let theOne = web3.utils.toBN(1);
        slippageValue = slippageValue.add(theOne);
        let direction = 0;
        let collateralizationFactor = testUtils.MILTON_10_USD;

        await testUtils.assertError(
            //when
            data.milton.openPosition(asset, collateral, slippageValue, collateralizationFactor, direction),
            //then
            'IPOR_9'
        );
    });

    it('should NOT open position because deposit amount too high', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let asset = data.tokenDai.address;
        let collateral = BigInt("1000000000000000000000001")
        let slippageValue = 3;
        let direction = 0;
        let collateralizationFactor = BigInt(10000000000000000000);

        await testUtils.assertError(
            //when
            data.milton.openPosition(asset, collateral, slippageValue, collateralizationFactor, direction),
            //then
            'IPOR_10'
        );
    });

    it('should open pay fixed position - simple case DAI', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt(10000000000000000000),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        let collateral = testUtils.MILTON_9063__63_USD;
        let openingFee = testUtils.MILTON_906__36_USD;

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        let miltonBalanceBeforePayout = testUtils.USD_14_000_18DEC;
        await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})

        let expectedMiltonTokenBalance = miltonBalanceBeforePayout + params.totalAmount;
        let expectedLiquidityPoolTotalBalance = miltonBalanceBeforePayout + openingFee;
        let expectedDerivativesTotalBalance = collateral;

        //when
        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //then
        await assertExpectedValues(
            params.asset,
            userTwo,
            userTwo,
            miltonBalanceBeforePayout,
            expectedMiltonTokenBalance,
            BigInt("9990000000000000000000000"),
            BigInt("9990000000000000000000000"),
            expectedLiquidityPoolTotalBalance,
            1,
            BigInt("9063636363636363636364"),
            testUtils.MILTON_20_USD,
            BigInt("0")
        );

        const actualDerivativesTotalBalance = BigInt(await (await testData.miltonStorage.balances(params.asset)).derivatives);

        assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
            `Incorrect derivatives total balance for ${params.asset} actual ${actualDerivativesTotalBalance}, expected ${expectedDerivativesTotalBalance}`)

    });


    it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
        await testUtils.setupTokenDaiInitialValues(data);
        let miltonBalanceBeforePayout = testUtils.USD_14_000_18DEC;
        let liquidationDepositAmount = testUtils.MILTON_20_USD

        let incomeTax = BigInt("0");

        let totalAmount = testUtils.USD_10_000_18DEC;
        let collateral = testUtils.MILTON_9063__63_USD;
        let openingFee = testUtils.MILTON_906__36_USD;

        let diffAfterClose = totalAmount - collateral - liquidationDepositAmount;

        let expectedOpenerUserTokenBalanceAfterPayOut = testUtils.USER_SUPPLY_18_DECIMALS - diffAfterClose;
        let expectedCloserUserTokenBalanceAfterPayOut = testUtils.USER_SUPPLY_18_DECIMALS - diffAfterClose;

        let expectedMiltonTokenBalance = miltonBalanceBeforePayout + diffAfterClose;
        let expectedLiquidityPoolTotalBalance = miltonBalanceBeforePayout + openingFee - incomeTax;

        await exetuceClosePositionTestCase(
            data.tokenDai.address, testUtils.MILTON_10_USD, 0, userTwo, userTwo,
            testUtils.PERCENTAGE_3_18DEC, testUtils.PERCENTAGE_3_18DEC, 0,
            miltonBalanceBeforePayout,
            expectedMiltonTokenBalance,
            expectedOpenerUserTokenBalanceAfterPayOut,
            expectedCloserUserTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalance,
            0, testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO, null
        );
    });

    it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity', async () => {

        let incomeTax = BigInt("6207970112079701121");
        let interestAmount = BigInt("62079701120797011207");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_365_PERCENTAGE, testUtils.MILTON_365_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });


    it('should NOT open position because Liquidity Pool balance is to low', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: BigInt("10000000000000000000000"), //10 000 USD
            slippageValue: 3,
            collateralizationFactor: BigInt(10000000000000000000),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        let closePositionTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        await data.warren.test_updateIndex(params.asset, BigInt("10000000000000000"), params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await data.warren.test_updateIndex(params.asset, BigInt("1600000000000000000"), params.openTimestamp, {from: userOne});
        await data.warren.test_updateIndex(params.asset, BigInt("50000000000000000"), closePositionTimestamp, {from: userOne});

        await data.iporAddressesManager.setAddress(keccak256("JOSEPH"), userOne);
        await testData.miltonStorage.subtractLiquidity(params.asset, params.totalAmount, {from: userOne})
        await data.iporAddressesManager.setAddress(keccak256("JOSEPH"), data.joseph.address);

        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, closePositionTimestamp, {from: userTwo}),
            //then
            'IPOR_14'
        );

    });
    it('should close position, DAI, owner, pay fixed, Milton earned, User lost > Collateral, before maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, before maturity', async () => {
        let incomeTax = BigInt("720124533001245333116");
        let interestAmount = BigInt("7201245330012453331164");
        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });


    it('should close position, DAI, owner, pay fixed, Milton earned, User lost < Deposit, after maturity', async () => {
        let incomeTax = BigInt("779224408468244081827");
        let interestAmount = BigInt("7792244084682440818267");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, before maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, before maturity', async () => {
        let incomeTax = BigInt("707708592777085925784");
        let interestAmount = BigInt("7077085927770859257843");
        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_120_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, pay fixed, Milton lost, User earned > Deposit, after maturity', async () => {

        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity', async () => {

        let incomeTax = testUtils.SPECIFIC_INCOME_TAX_CASE_1;
        let interestAmount = testUtils.SPECIFIC_INTEREST_AMOUNT_CASE_1;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_50_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });


    it('should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, before maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userThree,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });


    it('should NOT close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});


        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {from: userThree}),
            //then
            'IPOR_16');
    });

    it('should close position, DAI, not owner, pay fixed, Milton lost, User earned > Deposit, after maturity', async () => {

        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userThree,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, not owner, pay fixed, Milton lost, User earned < Deposit, after maturity', async () => {
        let incomeTax = BigInt("579079452054794521914");
        let interestAmount = BigInt("5790794520547945219137");

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userThree,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_50_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, before maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userThree,
            testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

    });

    it('should NOT close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, before maturity', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt(10000000000000000000),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});


        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {from: userThree}),
            //then
            'IPOR_16');
    });

    it('should close position, DAI, not owner, pay fixed, Milton earned, User lost < Deposit, after maturity', async () => {

        let incomeTax = BigInt("779224408468244081827");
        let interestAmount = BigInt("7792244084682440818267");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userThree,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

    });

    it('should close position, DAI, not owner, pay fixed, Milton earned, User lost > Deposit, after maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;
        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userThree,
            testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

    });

    it('should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price not changed, before maturity', async () => {

        let incomeTax = BigInt("6207970112079699258");
        let interestAmount = BigInt("62079701120796992583");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.PERCENTAGE_3_18DEC, testUtils.PERCENTAGE_3_18DEC, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, receive fixed, Milton earned, IPOR not changed, IBT price changed 25%, before maturity', async () => {
        let incomeTax = BigInt("6207970112079701121");
        let interestAmount = BigInt("62079701120797011207");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_365_PERCENTAGE, testUtils.MILTON_365_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, before maturity', async () => {

        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, receive fixed, Milton earned, User earned < Deposit, before maturity', async () => {

        let incomeTax = BigInt("254526774595267746325");
        let interestAmount = BigInt("2545267745952677463251");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, before maturity', async () => {

        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {

        let incomeTax = BigInt("720124533001245328026");
        let interestAmount = BigInt("7201245330012453280258");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_120_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, receive fixed, Milton lost, User earned > Deposit, after maturity', async () => {

        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, receive fixed, Milton lost, User earned < Deposit, after maturity', async () => {
        let incomeTax = BigInt("765318555417185551316");
        let interestAmount = BigInt("7653185554171855513162");

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

    });

    it('should close position, DAI, owner, receive fixed, Milton earned, User lost > Deposit, after maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_120_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

    });

    it('should close position, DAI, owner, receive fixed, Milton earned, User lost < Deposit, after maturity', async () => {
        let incomeTax = BigInt("592985305105853052424");
        let interestAmount = BigInt("5929853051058530524242");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_50_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, before maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

    });

    it('should NOT close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});

        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {from: userThree}),
            //then
            'IPOR_16');
    });

    it('should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, before maturity', async () => {

        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should NOT close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: 1,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_5_PERCENTAGE, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_120_PERCENTAGE, params.openTimestamp, {from: userOne});
        let endTimestamp = params.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await data.warren.test_updateIndex(params.asset, testUtils.MILTON_6_PERCENTAGE, endTimestamp, {from: userOne});

        //when
        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {from: userThree}),
            //then
            'IPOR_16');
    });

    it('should close position, DAI, not owner, receive fixed, Milton lost, User earned > Deposit, after maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, not owner, receive fixed, Milton lost, User earned < Deposit, after maturity', async () => {
        let incomeTax = BigInt("765318555417185551316");
        let interestAmount = BigInt("7653185554171855513162");

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, not owner, receive fixed, Milton earned, User lost > Deposit, after maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, not owner, receive fixed, Milton earned, User lost < Deposit, after maturity', async () => {
        let incomeTax = BigInt("592985305105853052424");
        let interestAmount = BigInt("5929853051058530524242");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_50_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should close position, DAI, owner, pay fixed, Milton earned, User lost > Deposit, after maturity', async () => {
        let incomeTax = BigInt("906363636363636363636");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_160_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
    });

    it('should NOT close position, because incorrect derivative Id', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await data.joseph.provideLiquidity(derivativeParamsFirst.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})
        await openPositionFunc(derivativeParamsFirst);

        await testUtils.assertError(
            //when
            data.milton.test_closePosition(0, openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: closerUserAddress}),
            //then
            'IPOR_22'
        );
    });

    it('should NOT close position, because derivative has incorrect status', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await data.joseph.provideLiquidity(derivativeParamsFirst.asset, testUtils.USD_14_000_18DEC + testUtils.USD_14_000_18DEC, {from: liquidityProvider})
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt(10000000000000000000),
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        await openPositionFunc(derivativeParams25days);

        let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS

        await data.milton.test_closePosition(1, endTimestamp, {from: closerUserAddress})

        await testUtils.assertError(
            //when
            data.milton.test_closePosition(1, endTimestamp, {from: closerUserAddress}),
            //then
            'IPOR_23'
        );
    });

    it('should NOT close position, because derivative not exists', async () => {
        //given
        let closerUserAddress = userTwo;
        let openTimestamp = Math.floor(Date.now() / 1000);

        await testUtils.assertError(
            //when
            data.milton.test_closePosition(0, openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: closerUserAddress}),
            //then
            'IPOR_22'
        );
    });


    it('should close only one position - close first position', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.joseph.provideLiquidity(derivativeParamsFirst.asset, testUtils.USD_14_000_18DEC + testUtils.USD_14_000_18DEC, {from: liquidityProvider})
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        await openPositionFunc(derivativeParams25days);
        let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(2);

        //when
        await data.milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        //then
        let actualDerivatives = await testData.miltonStorage.getPositions();
        let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);

        assert(expectedOpenedPositionsVol === actualOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`)

        let oneDerivative = actualDerivatives[0];

        assert(expectedDerivativeId === BigInt(oneDerivative.id),
            `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`)
    });

    it('should close only one position - close last position', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParamsFirst = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.joseph.provideLiquidity(derivativeParamsFirst.asset, testUtils.USD_14_000_18DEC + testUtils.USD_14_000_18DEC, {from: liquidityProvider})
        await data.warren.test_updateIndex(derivativeParamsFirst.asset, iporValueBeforeOpenPosition, derivativeParamsFirst.openTimestamp, {from: userOne});
        await openPositionFunc(derivativeParamsFirst);

        const derivativeParams25days = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS,
            from: openerUserAddress
        }
        await openPositionFunc(derivativeParams25days);
        let endTimestamp = openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS
        let expectedOpenedPositionsVol = 1;
        let expectedDerivativeId = BigInt(1);

        //when
        await data.milton.test_closePosition(2, endTimestamp, {from: closerUserAddress});

        //then
        let actualDerivatives = await testData.miltonStorage.getPositions();
        let actualOpenedPositionsVol = countOpenPositions(actualDerivatives);

        assert(expectedOpenedPositionsVol === actualOpenedPositionsVol,
            `Incorrect number of opened positions actual: ${actualOpenedPositionsVol}, expected: ${expectedOpenedPositionsVol}`)

        let oneDerivative = actualDerivatives[0];

        assert(expectedDerivativeId === BigInt(oneDerivative.id),
            `Incorrect derivative id actual: ${oneDerivative.id}, expected: ${expectedDerivativeId}`)

    });

    it('should close position with appropriate balance, DAI, owner, pay fixed, Milton lost, User earned < Deposit, after maturity, IPOR index calculated before close', async () => {

        let incomeTax = BigInt("579079452054794521914");
        let interestAmount = BigInt("5790794520547945219137");
        let asset = data.tokenDai.address;
        let collateralizationFactor = testUtils.MILTON_10_USD;
        let direction = 0;
        let openerUserAddress = userTwo;
        let closerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.MILTON_5_PERCENTAGE;
        let iporValueAfterOpenPosition = testUtils.MILTON_50_PERCENTAGE;
        let periodOfTimeElapsedInSeconds = testUtils.PERIOD_50_DAYS_IN_SECONDS;
        let expectedOpenedPositions = 0;
        let expectedDerivativesTotalBalance = testUtils.ZERO;
        let expectedLiquidationDepositTotalBalance = testUtils.ZERO;
        let expectedTreasuryTotalBalance = incomeTax;
        let expectedSoap = testUtils.ZERO;
        let openTimestamp = null;

        await testUtils.setupTokenDaiInitialValues(data);
        let miltonBalanceBeforePayout = testUtils.TC_LP_BALANCE_BEFORE_CLOSE;

        let closerUserEarned = testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT;
        let openerUserLost = testUtils.TC_OPENING_FEE + testUtils.TC_IPOR_PUBLICATION_AMOUNT
            + testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT - interestAmount + incomeTax;

        let closerUserLost = null;
        let openerUserEarned = null;

        if (openerUserAddress === closerUserAddress) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        let expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayout
            + testUtils.TC_OPENING_FEE + testUtils.TC_IPOR_PUBLICATION_AMOUNT - interestAmount + incomeTax;

        let expectedOpenerUserTokenBalanceAfterClose = testUtils.USER_SUPPLY_18_DECIMALS + openerUserEarned - openerUserLost;
        let expectedCloserUserTokenBalanceAfterClose = testUtils.USER_SUPPLY_18_DECIMALS + closerUserEarned - closerUserLost;

        let expectedLiquidityPoolTotalBalance = miltonBalanceBeforePayout - interestAmount + testUtils.TC_OPENING_FEE;

        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }
        const params = {
            asset: asset,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: collateralizationFactor,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUserAddress
        }

        if (miltonBalanceBeforePayout != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})
        }

        await data.warren.test_updateIndex(params.asset, iporValueBeforeOpenPosition, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;
        await data.warren.test_updateIndex(params.asset, iporValueAfterOpenPosition, params.openTimestamp, {from: userOne});

        //Important difference in opposite to other standard test cases - ipor is calculated right before closing position.
        await data.warren.test_updateIndex(params.asset, iporValueAfterOpenPosition, endTimestamp - 1, {from: userOne});

        //when
        await data.milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        //then
        await assertExpectedValues(
            params.asset,
            openerUserAddress,
            closerUserAddress,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserTokenBalanceAfterClose,
            expectedCloserUserTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalance,
            expectedOpenedPositions,
            expectedDerivativesTotalBalance,
            expectedLiquidationDepositTotalBalance,
            expectedTreasuryTotalBalance
        );

        const soapParams = {
            asset: params.asset,
            calculateTimestamp: endTimestamp,
            expectedSoap: expectedSoap,
            from: openerUserAddress
        }
        await assertSoap(soapParams);

    });

    it('should open many positions and arrays with ids have correct state, one user', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let openerUserAddress = userTwo;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: openerUserAddress
        }
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLength = 3
        let expectedDerivativeIdsLength = 3;

        await data.joseph.provideLiquidity(derivativeParams.asset, BigInt(3) * testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        //when
        await openPositionFunc(derivativeParams);
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);


        //then
        let actualUserDerivativeIds = await testData.miltonStorage.getUserDerivativeIds(openerUserAddress);
        let actualDerivativeIds = await testData.miltonStorage.getDerivativeIds();


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
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo
        }
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 1;
        let expectedDerivativeIdsLength = 3;

        await data.joseph.provideLiquidity(derivativeParams.asset, BigInt(3) * testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        //when
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //then
        let actualUserDerivativeIdsFirst = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await testData.miltonStorage.getUserDerivativeIds(userThree);
        let actualDerivativeIds = await testData.miltonStorage.getDerivativeIds();


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
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo
        }
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 2;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 2;

        await data.joseph.provideLiquidity(derivativeParams.asset, BigInt(3) * testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});

        //then
        let actualUserDerivativeIdsFirst = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await testData.miltonStorage.getUserDerivativeIds(userThree);
        let actualDerivativeIds = await testData.miltonStorage.getDerivativeIds();


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
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userTwo
        }
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 1;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 1;

        await data.joseph.provideLiquidity(derivativeParams.asset, BigInt(3) * testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        await openPositionFunc(derivativeParams);

        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userTwo;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
        await data.milton.test_closePosition(3, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userTwo});

        //then
        let actualUserDerivativeIdsFirst = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await testData.miltonStorage.getUserDerivativeIds(userThree);
        let actualDerivativeIds = await testData.miltonStorage.getDerivativeIds();


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
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree
        }
        await data.joseph.provideLiquidity(derivativeParams.asset, BigInt(2) * testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton.test_closePosition(1, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
        await data.milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS, {from: userThree});


        //then
        let actualUserDerivativeIdsFirst = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualDerivativeIds = await testData.miltonStorage.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)


    });

    it('should open two positions and close two positions - Arithmetic overflow - fix last byte difference - case 1 with minus 3', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree
        }
        await data.joseph.provideLiquidity(derivativeParams.asset, BigInt(2) * testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS - 3;
        await openPositionFunc(derivativeParams);

        //when
        await data.milton.test_closePosition(1, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});
        await data.milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS, {from: userThree});


        //then
        let actualUserDerivativeIdsFirst = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualDerivativeIds = await testData.miltonStorage.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)


    });

    it('should open two positions and close one position - Arithmetic overflow - last byte difference - case 1', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        let direction = 0;
        let iporValueBeforeOpenPosition = testUtils.PERCENTAGE_3_18DEC;
        let openTimestamp = Math.floor(Date.now() / 1000);

        const derivativeParams = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: testUtils.MILTON_10_USD,
            direction: direction,
            openTimestamp: openTimestamp,
            from: userThree
        }
        await data.joseph.provideLiquidity(derivativeParams.asset, BigInt(2) * testUtils.USD_14_000_18DEC, {from: liquidityProvider});
        await data.warren.test_updateIndex(derivativeParams.asset, iporValueBeforeOpenPosition, derivativeParams.openTimestamp, {from: userOne});

        let expectedUserDerivativeIdsLengthFirst = 0;
        let expectedUserDerivativeIdsLengthSecond = 0;
        let expectedDerivativeIdsLength = 0;

        //position 1, user first
        derivativeParams.from = userThree;
        derivativeParams.direction = 0;
        await openPositionFunc(derivativeParams);

        //position 2, user second
        derivativeParams.openTimestamp = derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS;
        derivativeParams.from = userThree;
        derivativeParams.direction = 0;
        await openPositionFunc(derivativeParams);

        await data.milton.test_closePosition(1, derivativeParams.openTimestamp + testUtils.PERIOD_25_DAYS_IN_SECONDS, {from: userThree});

        //when
        await data.milton.test_closePosition(2, derivativeParams.openTimestamp + testUtils.PERIOD_50_DAYS_IN_SECONDS, {from: userThree});


        //then
        let actualUserDerivativeIdsFirst = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualUserDerivativeIdsSecond = await testData.miltonStorage.getUserDerivativeIds(userTwo);
        let actualDerivativeIds = await testData.miltonStorage.getDerivativeIds();


        assert(expectedUserDerivativeIdsLengthFirst === actualUserDerivativeIdsFirst.length,
            `Incorrect first user derivative ids length actual: ${actualUserDerivativeIdsFirst.length}, expected: ${expectedUserDerivativeIdsLengthFirst}`)
        assert(expectedUserDerivativeIdsLengthSecond === actualUserDerivativeIdsSecond.length,
            `Incorrect second user derivative ids length actual: ${actualUserDerivativeIdsSecond.length}, expected: ${expectedUserDerivativeIdsLengthSecond}`)
        assert(expectedDerivativeIdsLength === actualDerivativeIds.length,
            `Incorrect derivative ids length actual: ${actualDerivativeIds.length}, expected: ${expectedDerivativeIdsLength}`)

    });


    it('should calculate income tax, 5%, not owner, Milton loses, user earns, |I| < D', async () => {
        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);

        let incomeTax = BigInt("382659277708592775658");
        let interestAmount = BigInt("7653185554171855513162");

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });

    it('should calculate income tax, 5%, Milton loses, user earns, |I| > D', async () => {

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);

        let incomeTax = BigInt("453181818181818181818");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });

    it('should calculate income tax, 5%, Milton earns, user loses, |I| < D', async () => {

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);

        let incomeTax = BigInt("360062266500622666558");
        let interestAmount = BigInt("7201245330012453331164");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });


    it('should calculate income tax, 5%, Milton earns, user loses, |I| > D', async () => {

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_5_PERCENTAGE);
        let incomeTax = BigInt("453181818181818181818");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });

    it('should calculate income tax, 100%, Milton loses, user earns, |I| < D', async () => {
        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_100_PERCENTAGE);
        let incomeTax = BigInt("7653185554171855513162");
        let interestAmount = BigInt("7653185554171855513162");

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });

    it('should calculate income tax, 100%, Milton loses, user earns, |I| > D', async () => {

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_100_PERCENTAGE);
        let incomeTax = BigInt("9063636363636363636364");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonLostAndUserEarn(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );
        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });

    it('should calculate income tax, 100%, Milton earns, user loses, |I| < D, to low liquidity pool', async () => {

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_100_PERCENTAGE);
        let incomeTax = BigInt("7201245330012453331164");
        let interestAmount = BigInt("7201245330012453331164");

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.MILTON_120_PERCENTAGE, testUtils.MILTON_5_PERCENTAGE, testUtils.PERIOD_25_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });


    it('should calculate income tax, 100%, Milton earns, user loses, |I| > D, to low liquidity pool', async () => {

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_100_PERCENTAGE);
        let incomeTax = BigInt("9063636363636363636364");
        let interestAmount = testUtils.TC_COLLATERAL;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            1, userTwo, userThree,
            testUtils.MILTON_5_PERCENTAGE, testUtils.MILTON_160_PERCENTAGE, testUtils.PERIOD_50_DAYS_IN_SECONDS,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            null, incomeTax, interestAmount
        );

        await data.iporConfigurationDai.setIncomeTaxPercentage(testUtils.MILTON_10_PERCENTAGE);
    });

    it('should open pay fixed position, DAI, custom Opening Fee for Treasury 50%', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});
        await data.iporConfigurationDai.setOpeningFeeForTreasuryPercentage(BigInt("50000000000000000"))

        let expectedOpeningFeeTotalBalance = testUtils.TC_OPENING_FEE;
        let expectedTreasuryTotalBalance = BigInt("45318181818181818182");

        let miltonBalanceBeforePayout = testUtils.USD_14_000_18DEC;
        let expectedLiquidityPoolTotalBalance = miltonBalanceBeforePayout + BigInt("861045454545454545454");
        await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})

        //when
        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidityPoolTotalBalance = BigInt(balance.liquidityPool);
        const actualTreasuryTotalBalance = BigInt(balance.treasury);

        assert(expectedOpeningFeeTotalBalance === actualOpeningFeeTotalBalance,
            `Incorrect opening fee total balance for ${params.asset}, actual:  ${actualOpeningFeeTotalBalance},
            expected: ${expectedOpeningFeeTotalBalance}`)
        assert(expectedLiquidityPoolTotalBalance === actualLiquidityPoolTotalBalance,
            `Incorrect Liquidity Pool total balance for ${params.asset}, actual:  ${actualLiquidityPoolTotalBalance},
            expected: ${expectedLiquidityPoolTotalBalance}`)
        assert(expectedTreasuryTotalBalance === actualTreasuryTotalBalance,
            `Incorrect Treasury total balance for ${params.asset}, actual:  ${actualTreasuryTotalBalance},
            expected: ${expectedTreasuryTotalBalance}`)

        await data.iporConfigurationDai.setOpeningFeeForTreasuryPercentage(ZERO);
    });

    it('should open pay fixed position, DAI, custom Opening Fee for Treasury 25%', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});
        await data.iporConfigurationDai.setOpeningFeeForTreasuryPercentage(BigInt("25000000000000000"))

        let expectedOpeningFeeTotalBalance = testUtils.TC_OPENING_FEE;
        let expectedTreasuryTotalBalance = BigInt("22659090909090909091");

        let miltonBalanceBeforePayout = testUtils.USD_14_000_18DEC;
        let expectedLiquidityPoolTotalBalance = miltonBalanceBeforePayout + BigInt("883704545454545454545");
        await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})

        //when
        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidityPoolTotalBalance = BigInt(balance.liquidityPool);
        const actualTreasuryTotalBalance = BigInt(balance.treasury);

        assert(expectedOpeningFeeTotalBalance === actualOpeningFeeTotalBalance,
            `Incorrect opening fee total balance for ${params.asset}, actual:  ${actualOpeningFeeTotalBalance},
            expected: ${expectedOpeningFeeTotalBalance}`)
        assert(expectedLiquidityPoolTotalBalance === actualLiquidityPoolTotalBalance,
            `Incorrect Liquidity Pool total balance for ${params.asset}, actual:  ${actualLiquidityPoolTotalBalance},
            expected: ${expectedLiquidityPoolTotalBalance}`)
        assert(expectedTreasuryTotalBalance === actualTreasuryTotalBalance,
            `Incorrect Treasury total balance for ${params.asset}, actual:  ${actualTreasuryTotalBalance},
            expected: ${expectedTreasuryTotalBalance}`)

        await data.iporConfigurationDai.setOpeningFeeForTreasuryPercentage(ZERO);
    });

    it('should NOT transfer Publication Fee to Charlie Treasury - caller not publication fee transferer', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //when
        await testUtils.assertError(
            //when
            data.milton.transferPublicationFee(data.tokenDai.address, BigInt("100")),
            //then
            'IPOR_31'
        );
    });

    it('should NOT transfer Publication Fee to Charlie Treasury - Charlie Treasury address incorrect', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        await data.iporAddressesManager.setAddress(keccak256("PUBLICATION_FEE_TRANSFERER"), admin);

        //when
        await testUtils.assertError(
            //when
            data.milton.transferPublicationFee(data.tokenDai.address, BigInt("100")),
            //then
            'IPOR_29'
        );
    });

    it('should transfer Publication Fee to Charlie Treasury - simple case 1', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        await data.iporAddressesManager.setAddress(keccak256("PUBLICATION_FEE_TRANSFERER"), admin);
        await data.iporAddressesManager.setCharlieTreasurer(params.asset, userThree);

        const transferedAmount = BigInt("100");

        //when
        await data.milton.transferPublicationFee(data.tokenDai.address, transferedAmount);

        //then
        let balance = await testData.miltonStorage.balances(params.asset);

        let expectedErc20BalanceCharlieTreasurer = testUtils.USER_SUPPLY_18_DECIMALS + transferedAmount;
        let actualErc20BalanceCharlieTreasurer = BigInt(await data.tokenDai.balanceOf(userThree));

        let expectedErc20BalanceMilton = testUtils.USD_14_000_18DEC + testUtils.USD_10_000_18DEC - transferedAmount;
        let actualErc20BalanceMilton = BigInt(await data.tokenDai.balanceOf (data.milton.address));

        let expectedPublicationFeeBalanceMilton = testUtils.MILTON_10_USD - transferedAmount;
        const actualPublicationFeeBalanceMilton = BigInt(balance.iporPublicationFee);

        assert(expectedErc20BalanceCharlieTreasurer === actualErc20BalanceCharlieTreasurer,
            `Incorrect ERC20 Charlie Treasurer balance for ${params.asset}, actual:  ${actualErc20BalanceCharlieTreasurer},
                expected: ${expectedErc20BalanceCharlieTreasurer}`)

        assert(expectedErc20BalanceMilton === actualErc20BalanceMilton,
            `Incorrect ERC20 Milton balance for ${params.asset}, actual:  ${actualErc20BalanceMilton},
                expected: ${expectedErc20BalanceMilton}`)

        assert(expectedPublicationFeeBalanceMilton === actualPublicationFeeBalanceMilton,
            `Incorrect Milton balance for ${params.asset}, actual:  ${actualPublicationFeeBalanceMilton},
                expected: ${expectedPublicationFeeBalanceMilton}`)
    });

    it('should NOT open pay fixed position, DAI, collateralization factor too low', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt(500),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        //when
        await testUtils.assertError(
            //when
            data.milton.openPosition(
                params.asset, params.totalAmount,
                params.slippageValue, params.collateralizationFactor,
                params.direction, {from: userTwo}),
            //then
            'IPOR_12'
        );
    });

    it('should NOT open pay fixed position, DAI, collateralization factor too high', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt("50000000000000000001"),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        //when
        await testUtils.assertError(
            //when
            data.milton.openPosition(
                params.asset, params.totalAmount,
                params.slippageValue, params.collateralizationFactor,
                params.direction, {from: userTwo}),
            //then
            'IPOR_34'
        );
    });


    it('should open pay fixed position, DAI, custom collateralization factor - simple case 1', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = {
            asset: data.tokenDai.address,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: BigInt("15125000000000000000"),
            direction: 0,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo
        }
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        await data.joseph.provideLiquidity(params.asset, testUtils.USD_14_000_18DEC, {from: liquidityProvider})

        //when
        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //then
        let actualDerivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let actualNotionalAmount = BigInt(actualDerivativeItem.item.notionalAmount);
        let expectedNotionalAmount = BigInt("130984799131378935939196");

        assert(expectedNotionalAmount === actualNotionalAmount,
            `Incorrect notional amount for ${params.asset}, actual:  ${actualNotionalAmount},
            expected: ${expectedNotionalAmount}`)

    });

    it('should open pay fixed position - liquidity pool utilisation not exceeded, custom utilisation', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        let closerUserEarned = ZERO;
        let openerUserLost = testUtils.TC_OPENING_FEE + testUtils.TC_IPOR_PUBLICATION_AMOUNT
            + testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT + testUtils.TC_COLLATERAL;

        let closerUserLost = openerUserLost;
        let openerUserEarned = closerUserEarned;

        let expectedOpenerUserTokenBalanceAfterClose = testUtils.USER_SUPPLY_18_DECIMALS + openerUserEarned - openerUserLost;
        let expectedCloserUserTokenBalanceAfterClose = testUtils.USER_SUPPLY_18_DECIMALS + closerUserEarned - closerUserLost;

        let miltonBalanceBeforePayout = testUtils.TC_LP_BALANCE_BEFORE_CLOSE;
        await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})

        let expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayout
            + testUtils.TC_OPENING_FEE + testUtils.TC_IPOR_PUBLICATION_AMOUNT
            + testUtils.TC_COLLATERAL + testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT;

        let expectedLiquidityPoolTotalBalance = miltonBalanceBeforePayout + testUtils.TC_OPENING_FEE;

        let oldLiquidityPoolMaxUtilizationPercentage = await data.iporConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();

        let liquidityPoolMaxUtilizationEdge = BigInt(608038055751904007);

        await data.iporConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationEdge);

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        //when
        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //then
        await assertExpectedValues(
            params.asset,
            userTwo,
            userTwo,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserTokenBalanceAfterClose,
            expectedCloserUserTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalance,
            1,
            testUtils.TC_COLLATERAL,
            testUtils.MILTON_20_USD,
            ZERO
        );

        await data.iporConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(oldLiquidityPoolMaxUtilizationPercentage);
    });


    it('should NOT open pay fixed position - when new position opened then liquidity pool utilisation exceeded, custom utilisation', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        let miltonBalanceBeforePayout = testUtils.TC_LP_BALANCE_BEFORE_CLOSE;
        await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})

        let oldLiquidityPoolMaxUtilizationPercentage = await data.iporConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();

        let liquidityPoolMaxUtilizationEdge = BigInt(608038055741904007);

        await data.iporConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationEdge);

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        //when
        await testUtils.assertError(
            //when
            data.milton.openPosition(
                params.asset, params.totalAmount,
                params.slippageValue, params.collateralizationFactor,
                params.direction, {from: userTwo}),
            //then
            'IPOR_35'
        );

        await data.iporConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(oldLiquidityPoolMaxUtilizationPercentage);
    });


    it('should NOT open pay fixed position - liquidity pool utilisation already exceeded, custom utilisation', async () => {

        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        let oldLiquidityPoolMaxUtilizationPercentage = await data.iporConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();
        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        let miltonBalanceBeforePayout = testUtils.USD_14_000_18DEC;
        await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})

        let liquiditiPoolMaxUtilizationEdge = BigInt(700036170982361327)
        await data.iporConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(liquiditiPoolMaxUtilizationEdge);

        //First open position not exceeded liquidity utilization
        await data.milton.openPosition(
            params.asset, params.totalAmount,
            params.slippageValue, params.collateralizationFactor,
            params.direction, {from: userTwo});

        //when
        //Second open position exceeded liquidity utilization
        await testUtils.assertError(
            //when
            data.milton.openPosition(
                params.asset, params.totalAmount,
                params.slippageValue, params.collateralizationFactor,
                params.direction, {from: userTwo}),
            //then
            'IPOR_35'
        );

        await data.iporConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(oldLiquidityPoolMaxUtilizationPercentage);
    });

    it('should NOT open pay fixed position - liquidity pool utilisation exceeded, liquidity pool and opening fee are ZERO', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        let oldLiquidityPoolMaxUtilizationPercentage = await data.iporConfigurationDai.getLiquidityPoolMaxUtilizationPercentage();
        let oldOpeningFeePercentage = await data.iporConfigurationDai.getOpeningFeePercentage();

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        await data.iporConfigurationDai.setOpeningFeePercentage(ZERO);
        //very high value
        await data.iporConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(BigInt(99999999999999999999999999999999999999999));


        await testUtils.assertError(
            //when
            data.milton.openPosition(
                params.asset, params.totalAmount,
                params.slippageValue, params.collateralizationFactor,
                params.direction, {from: userTwo}),
            //then
            'IPOR_35'
        );

        await data.iporConfigurationDai.setLiquidityPoolMaxUtilizationPercentage(oldLiquidityPoolMaxUtilizationPercentage);
        await data.iporConfigurationDai.setOpeningFeePercentage(oldOpeningFeePercentage);
    });

    it('should open pay fixed position - when open timestamp is long time ago', async () => {
        //given

        let veryLongTimeAgoTimestamp = 31536000; //1971-01-01
        let incomeTax = ZERO;
        let interestAmount = ZERO;

        await testCaseWhenMiltonEarnAndUserLost(
            data.tokenDai.address,
            testUtils.MILTON_10_USD,
            0, userTwo, userTwo,
            testUtils.PERCENTAGE_3_18DEC, testUtils.PERCENTAGE_3_18DEC, 0,
            0,
            testUtils.ZERO, testUtils.ZERO, incomeTax, testUtils.ZERO,
            veryLongTimeAgoTimestamp, incomeTax, interestAmount
        );
    });

    it('should NOT open pay fixed position - asset address not supported', async () => {

        //given

        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);

        await data.warren.updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, {from: userOne});

        let miltonBalanceBeforePayout = testUtils.USD_14_000_18DEC;
        await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})

        //when
        await testUtils.assertError(
            //when
            data.milton.openPosition(
                liquidityProvider, params.totalAmount,
                params.slippageValue, params.collateralizationFactor,
                params.direction, {from: userTwo}),
            //then
            'IPOR_39'
        );
    });

    it('should calculate Position Value - simple case 1', async () => {
        //given
        await testUtils.setupTokenDaiInitialValues(data);
        const params = testUtils.getStandardDerivativeParamsDAI(data);
        await data.warren.test_updateIndex(params.asset, testUtils.PERCENTAGE_3_18DEC, params.openTimestamp, {from: userOne});
        let miltonBalanceBeforePayout = testUtils.USD_14_000_18DEC;
        await data.joseph.provideLiquidity(params.asset, miltonBalanceBeforePayout, {from: liquidityProvider})
        await openPositionFunc(params);
        let derivativeItem = await testData.miltonStorage.getDerivativeItem(1);
        let expectedPositionValue = BigInt("-34764632627646354832");

        //when
        let actualPositionValue = BigInt(await data.milton.test_calculatePositionValue(params.openTimestamp + testUtils.PERIOD_14_DAYS_IN_SECONDS, derivativeItem.item));

        //then
        assert(expectedPositionValue === actualPositionValue,
            `Incorrect position value, actual: ${actualPositionValue}, expected: ${expectedPositionValue}`)

    });

    //TODO: !!!! test zamykania derywatywy, milton traci, trader zarabia, ale milton nie ma odpowiedniej ilosci kasy na balansie

    //TODO: check initial IBT

    //TODO: test w którym skutecznie przenoszone jest wlascicielstwo kontraktu na inna osobe
    //TODO: dodac test 1 otwarta long, zmiana indeksu, 2 otwarta short, zmiana indeksu, zamykamy 1 i 2, soap = 0

    //TODO: dodać test w którym zmieniamy konfiguracje w IporConfiguration i widac zmiany w Milton

    //TODO: testy na strukturze MiltonDerivatives

    //TODO: test when ipor not ready yet

    //TODO: create test when ipor index not yet created for specific asset

    //TODO: test na 1 sprwdzenie czy totalAmount wiekszy od fee
    //TODO: test na 2 sprwdzenie czy totalAmount wiekszy od fee (po przeliczeniu openingFeeAmount)
    //TODO: test na wysłanie USDT które ma 6 miejsc po przecinku i weryfikacja liczb

    //TODO: add test which checks emited events!!!
    //TODO: dopisać test zmiany na przykład adresu warrena i sprawdzenia czy widzi to milton
    //TODO: dopisac test zmiany adresu usdt i sprawdzenia czy widzi to milton
    //TODO: test sprawdzajacy wykonaniue przxelewu eth na miltona
    //TODO: test na podmianke miltonStorage - czy pokazuje nowy balance??


    const calculateSoap = async (params) => {
        return await data.milton.test_calculateSoap.call(params.asset, params.calculateTimestamp, {from: params.from});
    }

    const openPositionFunc = async (params) => {
        await data.milton.test_openPosition(
            params.openTimestamp,
            params.asset,
            params.totalAmount,
            params.slippageValue,
            params.collateralizationFactor,
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
        let actualDerivativeItem = await testData.miltonStorage.getDerivativeItem(derivativeId);
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

        // let actualDerivative = await data.milton.getOpenPosition(derivativeId);
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
        // assertDerivativeItem('Collateralization', expectedDerivative.collateralization, actualDerivative.collateralization);
        // assertDerivativeItem('Notional Amount', expectedDerivative.notionalAmount, actualDerivative.notionalAmount);
        // // assertDerivativeItem('Derivative starting timestamp', expectedDerivative.startingTimestamp, actualDerivative.startingTimestamp);
        // // assertDerivativeItem('Derivative ending timestamp', expectedDerivative.endingTimestamp, actualDerivative.endingTimestamp);
        // assertDerivativeItem('IPOR Index Value', expectedDerivative.indicator.iporIndexValue, actualDerivative.indicator.iporIndexValue);
        // assertDerivativeItem('IBT Price', expectedDerivative.indicator.ibtPrice, actualDerivative.indicator.ibtPrice);
        // assertDerivativeItem('IBT Quantity', expectedDerivative.indicator.ibtQuantity, actualDerivative.indicator.ibtQuantity);
        // assertDerivativeItem('Fixed Interest Rate', expectedDerivative.indicator.fixedInterestRate, actualDerivative.indicator.fixedInterestRate);
        // assertDerivativeItem('SOAP', expectedDerivative.indicator.soap, actualDerivative.indicator.soap);

    }

    const testCaseWhenMiltonEarnAndUserLost = async function (
        asset,
        collateralizationFactor,
        direction,
        openerUserAddress,
        closerUserAddress,
        iporValueBeforeOpenPosition,
        iporValueAfterOpenPosition,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalance,
        expectedLiquidationDepositTotalBalance,
        expectedTreasuryTotalBalance,
        expectedSoap,
        openTimestamp,
        incomeTax,
        interestAmount
    ) {
        await testUtils.setupTokenDaiInitialValues(data);
        let miltonBalanceBeforePayout = testUtils.TC_LP_BALANCE_BEFORE_CLOSE;

        let closerUserEarned = testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT;
        let openerUserEarned = null;

        let openerUserLost = testUtils.TC_OPENING_FEE + testUtils.TC_IPOR_PUBLICATION_AMOUNT + testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT + interestAmount;
        let closerUserLost = null;

        if (openerUserAddress === closerUserAddress) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }


        let expectedOpenerUserTokenBalanceAfterClose = testUtils.USER_SUPPLY_18_DECIMALS + openerUserEarned - openerUserLost;
        let expectedCloserUserTokenBalanceAfterClose = testUtils.USER_SUPPLY_18_DECIMALS + closerUserEarned - closerUserLost;

        let expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayout
            + testUtils.TC_OPENING_FEE + testUtils.TC_IPOR_PUBLICATION_AMOUNT + interestAmount;
        let expectedLiquidityPoolTotalBalance = miltonBalanceBeforePayout + testUtils.TC_OPENING_FEE + interestAmount - incomeTax;

        await exetuceClosePositionTestCase(
            asset,
            collateralizationFactor,
            direction,
            openerUserAddress,
            closerUserAddress,
            iporValueBeforeOpenPosition,
            iporValueAfterOpenPosition,
            periodOfTimeElapsedInSeconds,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserTokenBalanceAfterClose,
            expectedCloserUserTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalance,
            expectedOpenedPositions,
            expectedDerivativesTotalBalance,
            expectedLiquidationDepositTotalBalance,
            incomeTax,
            expectedSoap,
            openTimestamp
        );
    }

    const testCaseWhenMiltonLostAndUserEarn = async function (
        asset,
        collateralizationFactor,
        direction,
        openerUserAddress,
        closerUserAddress,
        iporValueBeforeOpenPosition,
        iporValueAfterOpenPosition,
        periodOfTimeElapsedInSeconds,
        expectedOpenedPositions,
        expectedDerivativesTotalBalance,
        expectedLiquidationDepositTotalBalance,
        expectedTreasuryTotalBalance,
        expectedSoap,
        openTimestamp,
        incomeTax,
        interestAmount
    ) {
        await testUtils.setupTokenDaiInitialValues(data);
        let miltonBalanceBeforePayout = testUtils.TC_LP_BALANCE_BEFORE_CLOSE;

        let closerUserEarned = testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT;
        let openerUserLost = testUtils.TC_OPENING_FEE + testUtils.TC_IPOR_PUBLICATION_AMOUNT
            + testUtils.TC_LIQUIDATION_DEPOSIT_AMOUNT - interestAmount + incomeTax;

        let closerUserLost = null;
        let openerUserEarned = null;

        if (openerUserAddress === closerUserAddress) {
            closerUserLost = openerUserLost;
            openerUserEarned = closerUserEarned;
        } else {
            closerUserLost = ZERO;
            openerUserEarned = ZERO;
        }

        let expectedMiltonUnderlyingTokenBalance = miltonBalanceBeforePayout
            + testUtils.TC_OPENING_FEE + testUtils.TC_IPOR_PUBLICATION_AMOUNT - interestAmount + incomeTax;

        let expectedOpenerUserTokenBalanceAfterClose = testUtils.USER_SUPPLY_18_DECIMALS + openerUserEarned - openerUserLost;
        let expectedCloserUserTokenBalanceAfterClose = testUtils.USER_SUPPLY_18_DECIMALS + closerUserEarned - closerUserLost;

        let expectedLiquidityPoolTotalBalance = miltonBalanceBeforePayout - interestAmount + testUtils.TC_OPENING_FEE;

        await exetuceClosePositionTestCase(
            asset,
            collateralizationFactor,
            direction,
            openerUserAddress,
            closerUserAddress,
            iporValueBeforeOpenPosition,
            iporValueAfterOpenPosition,
            periodOfTimeElapsedInSeconds,
            miltonBalanceBeforePayout,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserTokenBalanceAfterClose,
            expectedCloserUserTokenBalanceAfterClose,
            expectedLiquidityPoolTotalBalance,
            expectedOpenedPositions,
            expectedDerivativesTotalBalance,
            expectedLiquidationDepositTotalBalance,
            incomeTax,
            expectedSoap,
            openTimestamp
        );
    }

    const exetuceClosePositionTestCase = async function (
        asset,
        collateralizationFactor,
        direction,
        openerUserAddress,
        closerUserAddress,
        iporValueBeforeOpenPosition,
        iporValueAfterOpenPosition,
        periodOfTimeElapsedInSeconds,
        providedLiquidityAmount,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserTokenBalanceAfterPayOut,
        expectedCloserUserTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalance,
        expectedOpenedPositions,
        expectedDerivativesTotalBalance,
        expectedLiquidationDepositTotalBalance,
        expectedTreasuryTotalBalance,
        expectedSoap,
        openTimestamp
    ) {
        //given
        let localOpenTimestamp = null;
        if (openTimestamp != null) {
            localOpenTimestamp = openTimestamp;
        } else {
            localOpenTimestamp = Math.floor(Date.now() / 1000);
        }
        const params = {
            asset: asset,
            totalAmount: testUtils.USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: collateralizationFactor,
            direction: direction,
            openTimestamp: localOpenTimestamp,
            from: openerUserAddress
        }

        if (providedLiquidityAmount != null) {
            //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
            await data.joseph.provideLiquidity(params.asset, providedLiquidityAmount, {from: liquidityProvider})
        }

        await data.warren.test_updateIndex(params.asset, iporValueBeforeOpenPosition, params.openTimestamp, {from: userOne});
        await openPositionFunc(params);
        await data.warren.test_updateIndex(params.asset, iporValueAfterOpenPosition, params.openTimestamp, {from: userOne});

        let endTimestamp = params.openTimestamp + periodOfTimeElapsedInSeconds;

        //when
        await data.milton.test_closePosition(1, endTimestamp, {from: closerUserAddress});

        //then
        await assertExpectedValues(
            params.asset,
            openerUserAddress,
            closerUserAddress,
            providedLiquidityAmount,
            expectedMiltonUnderlyingTokenBalance,
            expectedOpenerUserTokenBalanceAfterPayOut,
            expectedCloserUserTokenBalanceAfterPayOut,
            expectedLiquidityPoolTotalBalance,
            expectedOpenedPositions,
            expectedDerivativesTotalBalance,
            expectedLiquidationDepositTotalBalance,
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
        miltonBalanceBeforePayout,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserTokenBalanceAfterPayOut,
        expectedCloserUserTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalance,
        expectedOpenedPositions,
        expectedDerivativesTotalBalance,
        expectedLiquidationDepositTotalBalance,
        expectedTreasuryTotalBalance
    ) {
        let actualDerivatives = await testData.miltonStorage.getPositions();
        let actualOpenPositionsVol = countOpenPositions(actualDerivatives);
        assert(expectedOpenedPositions === actualOpenPositionsVol,
            `Incorrect number of opened derivatives, actual:  ${actualOpenPositionsVol}, expected: ${expectedOpenedPositions}`)

        let expectedOpeningFeeTotalBalance = testUtils.MILTON_90_63_USD;
        let expectedPublicationFeeTotalBalance = testUtils.MILTON_10_USD;

        await assertBalances(
            asset,
            openerUserAddress,
            closerUserAddress,
            expectedOpenerUserTokenBalanceAfterPayOut,
            expectedCloserUserTokenBalanceAfterPayOut,
            expectedMiltonUnderlyingTokenBalance,
            expectedDerivativesTotalBalance,
            expectedOpeningFeeTotalBalance,
            expectedLiquidationDepositTotalBalance,
            expectedPublicationFeeTotalBalance,
            expectedLiquidityPoolTotalBalance,
            expectedTreasuryTotalBalance
        );

        let openerUserTokenBalanceBeforePayout = testUtils.MILTON_10_000_000_USD;
        let closerUserTokenBalanceBeforePayout = testUtils.MILTON_10_000_000_USD;


        const ammTokenBalanceAfterPayout = BigInt(await data.tokenDai.balanceOf(data.milton.address));
        const openerUserTokenBalanceAfterPayout = BigInt(await data.tokenDai.balanceOf(openerUserAddress));
        const closerUserTokenBalanceAfterPayout = BigInt(await data.tokenDai.balanceOf(closerUserAddress));

        let expectedSumOfBalancesBeforePayout = null;
        let actualSumOfBalances = null;

        if (openerUserAddress === closerUserAddress) {
            expectedSumOfBalancesBeforePayout = miltonBalanceBeforePayout + openerUserTokenBalanceBeforePayout;
            actualSumOfBalances = openerUserTokenBalanceAfterPayout + ammTokenBalanceAfterPayout;
        } else {
            expectedSumOfBalancesBeforePayout = miltonBalanceBeforePayout + openerUserTokenBalanceBeforePayout + closerUserTokenBalanceBeforePayout;
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

    const assertBalances = async (
        asset,
        openerUserAddress,
        closerUserAddress,
        expectedOpenerUserTokenBalance,
        expectedCloserUserTokenBalance,
        expectedMiltonUnderlyingTokenBalance,
        expectedDerivativesTotalBalance,
        expectedOpeningFeeTotalBalance,
        expectedLiquidationDepositTotalBalance,
        expectedPublicationFeeTotalBalance,
        expectedLiquidityPoolTotalBalance,
        expectedTreasuryTotalBalance
    ) => {

        let actualOpenerUserTokenBalance = null;
        let actualCloserUserTokenBalance = null;
        if (asset === data.tokenDai.address) {
            actualOpenerUserTokenBalance = BigInt(await data.tokenDai.balanceOf(openerUserAddress));
            actualCloserUserTokenBalance = BigInt(await data.tokenDai.balanceOf(closerUserAddress));
        }

        let balance = await testData.miltonStorage.balances(asset);

        const actualMiltonUnderlyingTokenBalance = BigInt(await data.miltonDevToolDataProvider.getMiltonTotalSupply(asset));
        const actualDerivativesTotalBalance = BigInt(balance.derivatives);
        const actualOpeningFeeTotalBalance = BigInt(balance.openingFee);
        const actualLiquidationDepositTotalBalance = BigInt(balance.liquidationDeposit);
        const actualPublicationFeeTotalBalance = BigInt(balance.iporPublicationFee);
        const actualLiquidityPoolTotalBalance = BigInt(balance.liquidityPool);
        const actualTreasuryTotalBalance = BigInt(balance.treasury);

        if (expectedMiltonUnderlyingTokenBalance !== null) {
            assert(actualMiltonUnderlyingTokenBalance === expectedMiltonUnderlyingTokenBalance,
                `Incorrect underlying token balance for ${asset} in Milton address, actual: ${actualMiltonUnderlyingTokenBalance}, expected: ${expectedMiltonUnderlyingTokenBalance}`);
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

        if (expectedLiquidationDepositTotalBalance !== null) {
            assert(expectedLiquidationDepositTotalBalance === actualLiquidationDepositTotalBalance,
                `Incorrect liquidation deposit fee total balance for ${asset}, actual:  ${actualLiquidationDepositTotalBalance}, expected: ${expectedLiquidationDepositTotalBalance}`)
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

    //TODO: add tests for pausable methods
});
