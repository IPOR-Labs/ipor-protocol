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
    let iporOracle = null;

    beforeEach(async () => {
        iporOracle = await IporOracle.deployed();
        amm = await IporAmmV1.deployed();
        await iporOracle.addUpdater(userOne);
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

    it('should open position', async () => {
        let asset = "DAI";
        let depositAmount = BigInt("100000000000000000000")
        let slippageValue = 3;
        let direction = 0;
        let leverage = 10;

        iporOracle.updateIndex(asset, BigInt(10000000000000000), {from: userOne});
        await amm.openPosition(asset, depositAmount, slippageValue, leverage, direction, {from: userTwo});
    });

    //TODO: check initial IBT
    //TODO: check open long position every parameter
    //TODO: check open short position every parameter
    //TODO: check derivativesTotalBalances
    //TODO: check openingFeeTotalBalances
    //TODO: check liquidationDepositFeeTotalBalances
    //TODO: check liquidationDepositFeeTotalBalances
    //TODO: create test when ipor index not yet created for specific asset
    //TODO: test na balance uzytkownika czy ma totalAmount
    //TODO: test na 1 sprwdzenie czy totalAmount wiekszy od fee
    //TODO: test na 2 sprwdzenie czy totalAmount wiekszy od fee (po przeliczeniu openingFeeAmount)
    //

    // it('should read Index from IPOR Oracle Smart Contract', async () => {
    //     //given
    //     let ticker = "USDT";
    //     let expectedValue = 111;
    //     let expectedInterestBearingToken = 234;
    //     await iporOracle.updateIndex(ticker, expectedValue, expectedInterestBearingToken, {from: updaterOne});
    //
    //     //when
    //     const iporIndexAmm = await amm.readIndex(ticker);
    //
    //     //then
    //     let actualValue = parseInt(iporIndexAmm.value);
    //     assert(expectedValue === actualValue);
    // });
});