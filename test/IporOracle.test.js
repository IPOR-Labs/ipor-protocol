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
        let ticker = "USDT";
        let expectedValue = 123;
        let expectedInterestBearingToken = 234;
        await iporOracle.addUpdater(updaterOne);

        //when
        await iporOracle.updateIndex(ticker, expectedValue, expectedInterestBearingToken, {from: updaterOne})

        //then
        const iporIndex = await iporOracle.getIndex(ticker);
        let actualValue = parseInt(iporIndex.value);
        let actualInterestBearingToken = parseInt(iporIndex.interestBearingToken);
        assert(expectedValue === actualValue);
        assert(expectedInterestBearingToken === actualInterestBearingToken);
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
        let expectedTickerOne = "USDT";
        let expectedTickerTwo = "DAI";
        let expectedIporIndexesSize = 2;
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.updateIndex(expectedTickerOne, 111, 234, {from: updaterOne});
        await iporOracle.updateIndex(expectedTickerTwo, 222, 234, {from: updaterOne});

        //when
        const iporIndexes = await iporOracle.getIndexes();

        //then
        assert(expectedIporIndexesSize === iporIndexes.length);
        assert(expectedTickerOne === iporIndexes[0].ticker);
        assert(expectedTickerTwo === iporIndexes[1].ticker);

    });

    it('should update existing IPOR Index', async () => {
        //given
        let ticker = "USDT";
        let expectedValueOne = 123;
        let expectedInterestBearingTokenOne = 234;
        let expectedValueTwo = 321;
        let expectedInterestBearingTokenTwo = 567;
        await iporOracle.addUpdater(updaterOne);

        //when
        await iporOracle.updateIndex(ticker, expectedValueOne, expectedInterestBearingTokenOne, {from: updaterOne});
        await iporOracle.updateIndex(ticker, expectedValueTwo, expectedInterestBearingTokenTwo, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(ticker);
        let actualValue = parseInt(iporIndex.value);
        let actualInterestBearingToken = parseInt(iporIndex.interestBearingToken);

        assert(actualValue === expectedValueTwo);
        assert(actualInterestBearingToken === expectedInterestBearingTokenTwo);
    });

});