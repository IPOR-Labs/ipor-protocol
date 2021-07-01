const { time } = require('@openzeppelin/test-helpers');
const IporOracle = artifacts.require('IporOracle');

const assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error))
        return;
    }
    assert(false);
}

contract('IporOracle', (accounts) => {

    const [admin, updaterOne, updaterTwo, user] = accounts;

    const INITIAL_INTEREST_BEARING_TOKEN_PRICE = BigInt(1e20);
    const YEAR_IN_SECONDS = 31536000;

    let iporOracle = null;

    beforeEach(async () => {
        iporOracle = await IporOracle.new();
    });

    it('should NOT update IPOR Index', async () => {
        await assertError(
            iporOracle.updateIndex("USDT", 123, {from: updaterOne}),
            'Reason given: 2'
        );
    });

    it('should update IPOR Index', async () => {
        //given
        let asset = "USDT";
        let expectedValue = 123;
        await iporOracle.addUpdater(updaterOne);

        //when
        await iporOracle.updateIndex(asset, expectedValue, {from: updaterOne})

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualValue = parseInt(iporIndex.indexValue);
        let actualIbtPrice = parseInt(iporIndex.ibtPrice);
        assert(expectedValue === actualValue);
    });

    it('should add IPOR Index Updater', async () => {
        await iporOracle.addUpdater(updaterOne);
        const updaters = await iporOracle.getUpdaters();
        assert(updaters.includes(updaterOne));
    });

    it('should NOT add IPOR Index Updater', async () => {
        await assertError(
            iporOracle.addUpdater(updaterTwo, {from: user}),
            'Reason given: 1'
        );
    });

    it('should remove IPOR Index Updater', async () => {
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.removeUpdater(updaterOne);
        const updaters = await iporOracle.getUpdaters();
        assert(!updaters.includes(updaterOne));
    });

    it('should NOT remove IPOR Index Updater', async () => {
        await assertError(
            iporOracle.removeUpdater(updaterTwo, {from: user}),
            'Reason given: 1'
        );
    });

    it('should retrieve list of IPOR Indexes', async () => {
        //given
        let expectedAssetOne = "USDT";
        let expectedAssetTwo = "DAI";
        let expectedIporIndexesSize = 2;
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.updateIndex(expectedAssetOne, 111, {from: updaterOne});
        await iporOracle.updateIndex(expectedAssetTwo, 222, {from: updaterOne});

        //when
        const iporIndexes = await iporOracle.getIndexes();

        //then
        assert(expectedIporIndexesSize === iporIndexes.length);
        assert(expectedAssetOne === iporIndexes[0].asset);
        assert(expectedAssetTwo === iporIndexes[1].asset);

    });

    it('should update existing IPOR Index', async () => {
        //given
        let asset = "USDT";
        let expectedValueOne = 123;
        let expectedValueTwo = 321;
        await iporOracle.addUpdater(updaterOne);

        //when
        await iporOracle.updateIndex(asset, expectedValueOne, {from: updaterOne});
        await iporOracle.updateIndex(asset, expectedValueTwo, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualValue = parseInt(iporIndex.indexValue);

        assert(actualValue === expectedValueTwo);
    });

    it('should calculate initial Interest Bearing Token Price', async () => {
        //given
        let asset = "USDT";
        await iporOracle.addUpdater(updaterOne);
        let decimals = web3.utils.toBN(1e16);
        let iporInxedValue = web3.utils.toBN(5);
        iporInxedValue = iporInxedValue.mul(decimals);

        //when
        await iporOracle.updateIndex(asset, iporInxedValue, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue)

        assert(actualIbtPrice == INITIAL_INTEREST_BEARING_TOKEN_PRICE,
            `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${INITIAL_INTEREST_BEARING_TOKEN_PRICE}`);
        assert(actualIndexValue == iporInxedValue, `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporInxedValue}`);

    });

    it('should calculate next Interest Bearing Token Price', async () => {
        //given
        let asset = "USDT";
        await iporOracle.addUpdater(updaterOne);
        let decimals = web3.utils.toBN(1e14);

        //first IPOR index update
        let iporInxedFirstValue = web3.utils.toBN(500);
        iporInxedFirstValue = iporInxedFirstValue.mul(decimals);
        await iporOracle.updateIndex(asset, iporInxedFirstValue, {from: updaterOne});

        await time.increase(YEAR_IN_SECONDS);

        let iporInxedSecondValue = web3.utils.toBN(510);
        iporInxedSecondValue = iporInxedSecondValue.mul(decimals);

        //when
        await iporOracle.updateIndex(asset, iporInxedSecondValue, {from: updaterOne});


        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue)
        let expectedIbtPrice = BigInt(web3.utils.toBN(105).mul(web3.utils.toBN(1e18)));

        assert(actualIbtPrice == expectedIbtPrice, `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${expectedIbtPrice}`);
        assert(actualIndexValue == iporInxedSecondValue, `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporInxedSecondValue}`);

    });

});