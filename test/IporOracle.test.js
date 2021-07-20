const {time} = require('@openzeppelin/test-helpers');
const TestIporOracleProxy = artifacts.require('TestIporOracleProxy');

const assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error), `Expected exception with message ${error}`);
        return;
    }
    assert(false);
}

contract('IporOracle', (accounts) => {

    const [admin, updaterOne, updaterTwo, user] = accounts;

    const INITIAL_INTEREST_BEARING_TOKEN_PRICE = BigInt(1e20);
    const YEAR_IN_SECONDS = 31536000;
    const MONTH_IN_SECONDS = 60 * 60 * 24 * 30;

    let iporOracle = null;

    beforeEach(async () => {
        iporOracle = await TestIporOracleProxy.new();
    });

    it('should NOT update IPOR Index', async () => {
        await assertError(
            iporOracle.updateIndex("ASSET_SYMBOL", 123, {from: updaterOne}),
            'Reason given: IPOR_2'
        );
    });

    it('should NOT update IPOR Index because input value is too low', async () => {
        await assertError(
            iporOracle.updateIndex("USDT", 123, {from: updaterOne}),
            'Reason given: IPOR_2'
        );
    });

    it('should update IPOR Index', async () => {
        //given
        let asset = "USDT";
        let expectedIndexValue = BigInt(1e20);
        await iporOracle.addUpdater(updaterOne);

        //when
        await iporOracle.updateIndex(asset, expectedIndexValue, {from: updaterOne})

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualIndexValue = BigInt(iporIndex.indexValue);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);

        assert(expectedIndexValue === actualIndexValue,
            `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValue}`);
        assert(INITIAL_INTEREST_BEARING_TOKEN_PRICE == actualIbtPrice,
            `Incorrect Interest Bearing Token Price ${actualIbtPrice}, expected ${INITIAL_INTEREST_BEARING_TOKEN_PRICE}`)
    });

    it('should add IPOR Index Updater', async () => {
        await iporOracle.addUpdater(updaterOne);
        const updaters = await iporOracle.getUpdaters();
        assert(updaters.includes(updaterOne), `Updater ${updaterOne} should exist in list of updaters in IPOR Oracle, but not exists`);
    });

    it('should NOT add IPOR Index Updater', async () => {
        await assertError(
            iporOracle.addUpdater(updaterTwo, {from: user}),
            'Reason given: IPOR_1'
        );
    });

    it('should remove IPOR Index Updater', async () => {
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.removeUpdater(updaterOne);
        const updaters = await iporOracle.getUpdaters();
        assert(!updaters.includes(updaterOne), `Updater ${updaterOne} should not exist in list of updaters in IPOR Oracle, but exists`);
    });

    it('should NOT remove IPOR Index Updater', async () => {
        await assertError(
            iporOracle.removeUpdater(updaterTwo, {from: user}),
            'Reason given: IPOR_1'
        );
    });

    it('should retrieve list of IPOR Indexes', async () => {
        //given
        let expectedAssetOne = "USDT";
        let expectedAssetTwo = "DAI";
        let expectedIporIndexesSize = 2;
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.updateIndex(expectedAssetOne, BigInt(1e20), {from: updaterOne});
        await iporOracle.updateIndex(expectedAssetTwo, BigInt(1e20), {from: updaterOne});

        //when
        const iporIndexes = await iporOracle.getIndexes();

        //then
        assert(expectedIporIndexesSize === iporIndexes.length,
            `Incorrect IPOR indexes size ${iporIndexes.length}, expected ${expectedIporIndexesSize}`);
        assert(expectedAssetOne === iporIndexes[0].asset,
            `Incorrect asset on first position in indexes ${iporIndexes[0].asset}, expected ${expectedAssetOne}`);
        assert(expectedAssetTwo === iporIndexes[1].asset,
            `Incorrect asset on second position in indexes ${iporIndexes[1].asset}, expected ${expectedAssetTwo}`);

    });

    it('should update existing IPOR Index', async () => {
        //given
        let asset = "USDT";
        let expectedIndexValueOne = BigInt("123000000000000000000");
        let expectedIndexValueTwo = BigInt("321000000000000000000");
        await iporOracle.addUpdater(updaterOne);

        //when
        await iporOracle.updateIndex(asset, expectedIndexValueOne, {from: updaterOne});
        await iporOracle.updateIndex(asset, expectedIndexValueTwo, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        assert(actualIndexValue === expectedIndexValueTwo, `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValueOne}`);
    });

    it('should calculate initial Interest Bearing Token Price', async () => {
        //given
        let asset = "USDT";
        await iporOracle.addUpdater(updaterOne);
        let iporIndexValue = BigInt("500000000000000000000");

        //when
        await iporOracle.updateIndex(asset, iporIndexValue, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        assert(actualIbtPrice === INITIAL_INTEREST_BEARING_TOKEN_PRICE,
            `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${INITIAL_INTEREST_BEARING_TOKEN_PRICE}`);
        assert(actualIndexValue === iporIndexValue, `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporIndexValue}`);

    });

    it('should calculate next Interest Bearing Token Price - one year period', async () => {
        //given
        let asset = "USDT";
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.updateIndex(asset, BigInt("50000000000000000"), {from: updaterOne});
        await time.increase(YEAR_IN_SECONDS);
        let iporIndexSecondValue = BigInt("51000000000000000");

        //when
        await iporOracle.updateIndex(asset, iporIndexSecondValue, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);
        let expectedIbtPrice = BigInt("105000000000000000000");

        assert(actualIbtPrice === expectedIbtPrice, `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${expectedIbtPrice}`);
        assert(actualIndexValue === iporIndexSecondValue, `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporIndexSecondValue}`);

    });

    it('should calculate next Interest Bearing Token Price - one month period', async () => {
        //given
        let asset = "USDT";
        let updateDate = Math.floor(Date.now() / 1000);
        await iporOracle.addUpdater(updaterOne);
        await iporOracle.test_updateIndex(asset, BigInt("50000000000000000"), updateDate, {from: updaterOne});
        updateDate = updateDate + MONTH_IN_SECONDS;
        let iporIndexSecondValue = BigInt("60000000000000000");

        //when
        await iporOracle.test_updateIndex(asset, iporIndexSecondValue, updateDate, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        let expectedIbtPrice = BigInt("100410958904109589000");

        assert(actualIbtPrice === expectedIbtPrice, `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${expectedIbtPrice}`);
        assert(actualIndexValue === iporIndexSecondValue, `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporIndexSecondValue}`);

    });

    it('should calculate next after next Interest Bearing Token Price - half year and three months snapshots', async () => {
        //given
        let asset = "USDT";
        await iporOracle.addUpdater(updaterOne);
        let updateDate = Math.floor(Date.now() / 1000);
        await iporOracle.test_updateIndex(asset, BigInt("50000000000000000"), updateDate, {from: updaterOne});
        updateDate = updateDate + YEAR_IN_SECONDS / 2;
        await iporOracle.test_updateIndex(asset, BigInt("60000000000000000"), updateDate, {from: updaterOne});
        updateDate = updateDate + YEAR_IN_SECONDS / 4;

        let iporIndexThirdValue = BigInt("70000000000000000");

        //when
        await iporOracle.test_updateIndex(asset, iporIndexThirdValue, updateDate, {from: updaterOne});

        //then
        const iporIndex = await iporOracle.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        let expectedIbtPrice = BigInt("104037500000000000000");

        assert(actualIbtPrice === expectedIbtPrice, `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${expectedIbtPrice}`);
        assert(actualIndexValue === iporIndexThirdValue, `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporIndexThirdValue}`);

    });

    it('should NOT update IPOR Index - wrong input arrays', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await iporOracle.addUpdater(updaterOne);
        let assets = ["USDC", "DAI"];
        let indexValues = [BigInt("50000000000000000")];

        await assertError(
            //when
            iporOracle.test_updateIndexes(assets, indexValues, updateDate, {from: updaterOne}),
            //then
            'Reason given: IPOR_18'
        );
    });

    it('should update IPOR Index - correct input arrays', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await iporOracle.addUpdater(updaterOne);
        let assets = ["USDC", "DAI"];
        let indexValues = [BigInt("80000000000000000"), BigInt("70000000000000000")];

        //when
        await iporOracle.test_updateIndexes(assets, indexValues, updateDate, {from: updaterOne})

        //then
        for (let i = 0; i < assets.length; i++) {
            const iporIndex = await iporOracle.getIndex(assets[i]);
            let actualIndexValue = BigInt(iporIndex.indexValue);
            assert(actualIndexValue === indexValues[i], `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${indexValues[i]}`);
        }
    });

});