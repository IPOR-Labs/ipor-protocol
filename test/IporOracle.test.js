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

    let iporOracle = null;

    before(async () => {
        iporOracle = await IporOracle.deployed();
    });

    it('should not update IPOR Index', async () => {
        assertError(
            iporOracle.updateIndex("USDT", 123, 456, {from: updaterOne}),
            'Reason given: 2'
        );
    });

    it('should update IPOR Index', async () => {
        //given
        let asset = "USDT";
        let expectedValue = 123;
        let expectedIbtPrice = 234;
        await iporOracle.addUpdater(updaterOne);

        //when
        await iporOracle.updateIndex(asset, expectedValue, expectedIbtPrice, {from: updaterOne})

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualValue = parseInt(iporIndex.value);
        let actualIbtPrice = parseInt(iporIndex.ibtPrice);
        assert(expectedValue === actualValue);
        assert(expectedIbtPrice === actualIbtPrice);
    });

    it('should add IPOR Index Updater', async () => {
        await iporOracle.addUpdater(updaterOne);
        const updaters = await iporOracle.getUpdaters();
        assert(updaters.includes(updaterOne));
    });

    it('should not add IPOR Index Updater', async () => {
        assertError(
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

    it('should not remove IPOR Index Updater', async () => {
        assertError(
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
        await iporOracle.updateIndex(expectedAssetOne, 111, 234, {from: updaterOne});
        await iporOracle.updateIndex(expectedAssetTwo, 222, 234, {from: updaterOne});

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
        let expectedIbtPriceOne = 234;
        let expectedValueTwo = 321;
        let expectedIbtPriceTwo = 567;
        await iporOracle.addUpdater(updaterOne);

        //when
        await iporOracle.updateIndex(asset, expectedValueOne, expectedIbtPriceOne, {from: updaterOne});
        await iporOracle.updateIndex(asset, expectedValueTwo, expectedIbtPriceTwo, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualValue = parseInt(iporIndex.value);
        let actualIbtPrice = parseInt(iporIndex.ibtPrice);

        assert(actualValue === expectedValueTwo);
        assert(actualIbtPrice === expectedIbtPriceTwo);
    });

});