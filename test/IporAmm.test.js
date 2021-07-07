const IporAmmV1 = artifacts.require('IporAmmV1');
const IporOracle = artifacts.require('IporOracle');
const IporPool = artifacts.require("IporPool");
const SimpleToken = artifacts.require('SimpleToken');

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

    const [admin, userOne, userTwo, _] = accounts;

    let amm = null;
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporOracle = null;

    beforeEach(async () => {
        iporOracle = await IporOracle.deployed();
        amm = await IporAmmV1.deployed();
        await iporOracle.addUpdater(userOne);
        tokenDai = await SimpleToken.at(await amm.tokens("DAI"));
        tokenUsdt = await SimpleToken.at(await amm.tokens("USDT"));
        tokenUsdc = await SimpleToken.at(await amm.tokens("USDC"));
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
            'Reason given: 4'
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
            'Reason given: 5'
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
            'Reason given: 9'
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
            'Reason given: 10'
        );
    });

    it('should open pay fixed position - simple case DAI', async () => {
        //given
        let asset = "DAI";
        let depositAmount = BigInt("100000000000000000000")
        let slippageValue = 3;
        let direction = 0;
        let leverage = 10;
        iporOracle.updateIndex(asset, BigInt("30000000000000000"), {from: userOne});

        //when
        await amm.openPosition(asset, depositAmount, slippageValue, leverage, direction, {from: userTwo});

        //then
        const expectedDerivativesTotalBalance = BigInt("69300000000000000000");
        const expectedOpeningFee = BigInt("700000000000000000");
        const expectedLiquidationDepositFee = BigInt("20000000000000000000");
        const expectedIporPublicationFee = BigInt("10000000000000000000");
        const expectedLiquidityPoolTotalBalance = expectedOpeningFee;

        const actualDerivativesTotalBalance = BigInt(await amm.derivativesTotalBalances(asset));
        const actualOpeningFeeTotalBalance = BigInt(await amm.openingFeeTotalBalances(asset));
        const actualLiquidationDepositFeeTotalBalance = BigInt(await amm.liquidationDepositFeeTotalBalances(asset));
        const actualPublicationFeeTotalBalance = BigInt(await amm.iporPublicationFeeTotalBalances(asset));
        const actualLiquidityPoolTotalBalance = BigInt(await amm.liquidityPoolTotalBalances(asset));

        assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
            `Incorrect derivatives total balance for ${asset} ${actualDerivativesTotalBalance}, expected ${expectedDerivativesTotalBalance}`)
        assert(expectedOpeningFee === actualOpeningFeeTotalBalance,
            `Incorrect opening fee total balance for ${asset} ${actualOpeningFeeTotalBalance}, expected ${expectedOpeningFee}`)
        assert(expectedLiquidationDepositFee === actualLiquidationDepositFeeTotalBalance,
            `Incorrect liquidation deposit fee total balance for ${asset} ${actualLiquidationDepositFeeTotalBalance}, expected ${expectedLiquidationDepositFee}`)
        assert(expectedIporPublicationFee === actualPublicationFeeTotalBalance,
            `Incorrect ipor publication fee total balance for ${asset} ${actualPublicationFeeTotalBalance}, expected ${expectedIporPublicationFee}`)

        assert(expectedLiquidityPoolTotalBalance === actualLiquidityPoolTotalBalance,
            `Incorrect Liquidity Pool total balance for ${asset} ${actualLiquidityPoolTotalBalance}, expected ${expectedLiquidityPoolTotalBalance}`)

        let actualAmmTotalSupplyForDai = BigInt(await amm.getTotalSupply(asset));

        assert(depositAmount === actualAmmTotalSupplyForDai,
            `Incorrect total supply of ${asset} tokens in AMM address ${actualAmmTotalSupplyForDai}, expected ${depositAmount}`);


        let actualUserTwoDAITokenBalance = await tokenDai.balanceOf(userTwo);
        const expectedUserTwoDAITokenBalance = BigInt("9999900000000000000000000");

        assert(expectedUserTwoDAITokenBalance.toString()  === actualUserTwoDAITokenBalance.toString(),
            `Incorrect ${asset} token balance in user wallet ${actualUserTwoDAITokenBalance}, expected ${expectedUserTwoDAITokenBalance}`);
    });

    it('should close pay fixed position - simple case DAI', async () => {
        //given
        let asset = "DAI";
        let depositAmount = BigInt("100000000000000000000")
        let slippageValue = 3;
        let direction = 0;
        let leverage = 10;
        iporOracle.updateIndex(asset, BigInt("30000000000000000"), {from: userOne});
        await amm.openPosition(asset, depositAmount, slippageValue, leverage, direction, {from: userTwo});

        //when
        await amm.closePosition(1);

        //then

    });

    //TODO: test when ipor not ready yet

    //TODO: check initial IBT
    //TODO: check open short position every parameter
    //TODO: create test when ipor index not yet created for specific asset

    //TODO: test if opening fee is part of liquidity pool

    //TODO: test na 1 sprwdzenie czy totalAmount wiekszy od fee
    //TODO: test na 2 sprwdzenie czy totalAmount wiekszy od fee (po przeliczeniu openingFeeAmount)
    //TODO: test na wysłanie USDT które ma 6 miejsc po przecinku i weryfikacja liczb
});