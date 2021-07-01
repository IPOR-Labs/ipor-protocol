const IporAmmV1 = artifacts.require('IporAmmV1');
const IporOracle = artifacts.require('IporOracle');
const IporPool = artifacts.require("IporPool");
const SimpleToken = artifacts.require('SimpleToken');

const assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error))
        return;
    }
    assert(false);
}

contract('IporAmm', (accounts) => {

    const [admin, updaterOne, updaterTwo, user, usdtToken, usdcToken, daiToken] = accounts;

    let amm = null;
    let iporOracle = null;

    beforeEach(async () => {
        // iporOracle = await IporOracle.new();
        //
        //
        // const fakeUsdt = await SimpleToken.new('Fake USDT', 'fUSDT', '10000000000000000000000');
        // const usdtPool = await IporPool.new(fakeUsdt.address);
        //
        // const fakeUsdc = await SimpleToken.new('Fake USDC', 'fUSDC', '10000000000000000000000');
        // const usdcPool = await IporPool.new(fakeUsdc.address);
        //
        // const fakeDai = await SimpleToken.new('Fake DAI', 'fDAI', '10000000000000000000000');
        // const daiPool = await IporPool.new(fakeDai.address);
        //
        // amm = await IporAmmV1.new(iporOracle.address, usdtPool.address, usdcPool.address, daiPool.address);
        iporOracle = await IporOracle.deployed();
        amm = await IporAmmV1.deployed();
        await iporOracle.addUpdater(updaterOne);

    });

    it('should NOT open position because notional amount too low', async () => {
        //given
        let asset = "DAI";
        let notionalAmount = 0;
        let depositAmount = 10;
        let slippageValue = 3;
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 3'
        );
    });

    it('should NOT open position because deposit amount too low', async () => {
        //given
        let asset = "DAI";
        let notionalAmount = 10;
        let depositAmount = 0;
        let slippageValue = 3;
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 4'
        );
    });

    it('should NOT open position because slippage too low', async () => {
        //given
        let asset = "DAI";
        let notionalAmount = 100;
        let depositAmount = 10;
        let slippageValue = 0;
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 5'
        );
    });

    it('should NOT open position because notional amount lower than deposit amount', async () => {
        //given
        let asset = "DAI";
        let notionalAmount = 10;
        let depositAmount = 20;
        let slippageValue = 3;
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 6'
        );
    });

    it('should NOT open position because notional amount equal deposit amount', async () => {
        //given
        let asset = "DAI";
        let notionalAmount = 10;
        let depositAmount = 10;
        let slippageValue = 3;
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 6'
        );
    });

    it('should NOT open position because notional amount equal deposit amount', async () => {
        //given
        let asset = "FAKE";
        let notionalAmount = 100;
        let depositAmount = 10;
        let slippageValue = 3;
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 7'
        );
    });

    it('should NOT open position because notional amount equal deposit amount', async () => {
        //given
        let asset = "USDT";
        let notionalAmount = 100;
        let depositAmount = 10;
        let slippageValue = 3;
        let direction = 3;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 8'
        );
    });

    it('should NOT open position because slippage too high', async () => {
        //given
        let asset = "DAI";
        let notionalAmount = 100;
        let depositAmount = 10;
        let slippageValue = web3.utils.toBN(1e18);
        let theOne = web3.utils.toBN(1);
        slippageValue = slippageValue.add(theOne);
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 9'
        );
    });

    it('should NOT open position because notional amount too high', async () => {
        //given
        let asset = "DAI";
        let notionalAmount = web3.utils.toBN(1e18);
        let theOne = web3.utils.toBN(1);
        notionalAmount = notionalAmount.add(theOne);
        let depositAmount = 10;
        let slippageValue = 3;
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 11'
        );
    });

    it('should NOT open position because deposit amount too high', async () => {
        //given
        let asset = "DAI";
        let notionalAmount = 10;
        let depositAmount = web3.utils.toBN(1e18);
        let theOne = web3.utils.toBN(1);
        depositAmount = depositAmount.add(theOne);
        let slippageValue = 3;
        let direction = 0;

        await assertError(
            //when
            amm.openPosition(asset, notionalAmount, depositAmount, slippageValue, direction),
            //then
            'Reason given: 10'
        );
    });

    //TODO: check initial IBT
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