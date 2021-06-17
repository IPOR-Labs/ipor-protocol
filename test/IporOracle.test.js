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
            iporOracle.updateIndex("USDT", 123, {from: updaterOne}),
            'Reason given: 2'
        );
    });

    it('should update IPOR Index', async () => {
        let ticker = "USDT";
        let value = 123;
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.updateIndex(ticker, value, {from: updaterOne})
        const iporIndex = await iporOracle.getIndex(ticker);
        let convValue = parseInt(iporIndex.value);
        assert(convValue === value);
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
        let tickerOne = "USDT";
        let tickerTwo = "DAI";
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.updateIndex(tickerOne, 111, {from: updaterOne});
        await iporOracle.updateIndex(tickerTwo, 222, {from: updaterOne});
        const iporIndexes = await iporOracle.getIndexes();
        assert(2 === iporIndexes.length);
        assert(tickerOne === iporIndexes[0].ticker);
        assert(tickerTwo === iporIndexes[1].ticker);

    });

    it('should update existing IPOR Index', async () => {
        let ticker = "USDT";
        let valueOne = 123;
        let valueTwo = 321;
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.updateIndex(ticker, valueOne, {from: updaterOne});
        await iporOracle.updateIndex(ticker, valueTwo, {from: updaterOne});
        const iporIndex = await iporOracle.getIndex(ticker);
        let convValue = parseInt(iporIndex.value);
        assert(convValue === valueTwo);
    });

});