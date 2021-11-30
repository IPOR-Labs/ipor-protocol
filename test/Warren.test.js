const testUtils = require("./TestUtils.js");
const WarrenDevToolDataProvider = artifacts.require('WarrenDevToolDataProvider');

contract('Warren', (accounts) => {

    const [admin, updaterOne, updaterTwo, user] = accounts;

    const YEAR_IN_SECONDS = 31536000;
    const MONTH_IN_SECONDS = 60 * 60 * 24 * 30;

    let data = null;
    let testData = null;
    let warrenDevToolDataProvider = null;

    before(async () => {
        data = await testUtils.prepareData();
        warrenDevToolDataProvider = await WarrenDevToolDataProvider.new(data.iporConfiguration.address);
    });

    beforeEach(async () => {
        testData = await testUtils.prepareTestData([admin, updaterOne, updaterTwo, user], ["USDC", "USDT", "DAI"], data);
    });

    it('should NOT update IPOR Index, because sender is not an updater', async () => {
        await testUtils.assertError(
            data.warren.updateIndex(testData.tokenUsdt.address, 123, {from: user}),
            'IPOR_2'
        );
    });

    it('should NOT update IPOR Index because Warren is not on list of updaters', async () => {
        //given
        await testData.warrenStorage.removeUpdater(data.warren.address);

        await testUtils.assertError(
            //when
            data.warren.updateIndex(testData.tokenUsdt.address, 123, {from: updaterTwo}),
            //then
            'IPOR_2'
        );
        await testData.warrenStorage.addUpdater(data.warren.address);
    });

    it('should update IPOR Index', async () => {
        //given
        let asset = testData.tokenDai.address;
        let expectedIndexValue = BigInt(1e20);
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);

        //when
        await data.warren.updateIndex(asset, expectedIndexValue, {from: updaterOne})

        //then
        const iporIndex = await data.warren.getIndex(asset);
        let actualIndexValue = BigInt(iporIndex.indexValue);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);

        assert(expectedIndexValue === actualIndexValue,
            `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValue}`);
        assert(testUtils.TC_IBT_PRICE_DAI_18DEC == actualIbtPrice,
            `Incorrect Interest Bearing Token Price ${actualIbtPrice}, expected ${testUtils.TC_IBT_PRICE_DAI_18DEC}`)
    });

    it('should add IPOR Index Updater', async () => {
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const updaters = await testData.warrenStorage.getUpdaters();
        assert(updaters.includes(updaterOne), `Updater ${updaterOne} should exist in list of updaters in IPOR Oracle, but not exists`);
    });

    it('should NOT add IPOR Index Updater', async () => {
        await testUtils.assertError(
            testData.warrenStorage.addUpdater(updaterTwo, {from: user}),
            'Ownable: caller is not the owner'
        );
    });

    it('should remove IPOR Index Updater', async () => {
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.removeUpdater(updaterOne);
        const updaters = await testData.warrenStorage.getUpdaters();
        assert(!updaters.includes(updaterOne), `Updater ${updaterOne} should not exist in list of updaters in IPOR Oracle, but exists`);
    });

    it('should NOT remove IPOR Index Updater', async () => {
        await testUtils.assertError(
            testData.warrenStorage.removeUpdater(updaterTwo, {from: user}),
            'Ownable: caller is not the owner'
        );
    });

    it('should retrieve list of IPOR Indexes', async () => {
        //given
        let expectedAssetOne = testData.tokenUsdt.address;
        let expectedAssetSymbolOne = "USDT";
        let expectedAssetTwo = testData.tokenDai.address;
        let expectedAssetSymbolTwo = "DAI";
        let expectedIporIndexesSize = 2;
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        await data.warren.updateIndex(expectedAssetOne, BigInt(1e8), {from: updaterOne});
        await data.warren.updateIndex(expectedAssetTwo, BigInt(1e20), {from: updaterOne});

        //when
        const iporIndexes = await warrenDevToolDataProvider.getIndexes();

        //then
        assert(expectedIporIndexesSize === iporIndexes.length,
            `Incorrect IPOR indexes size ${iporIndexes.length}, expected ${expectedIporIndexesSize}`);
        assert(expectedAssetSymbolOne === iporIndexes[0].asset,
            `Incorrect asset on first position in indexes ${iporIndexes[0].asset}, expected ${expectedAssetOne}`);
        assert(expectedAssetSymbolTwo === iporIndexes[1].asset,
            `Incorrect asset on second position in indexes ${iporIndexes[1].asset}, expected ${expectedAssetTwo}`);

    });

    it('should update existing IPOR Index', async () => {
        //given
        let asset = testData.tokenUsdt.address;
        let expectedIndexValueOne = BigInt("123000000000000000000");
        let expectedIndexValueTwo = BigInt("321000000000000000000");
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);

        //when
        await data.warren.updateIndex(asset, expectedIndexValueOne, {from: updaterOne});
        await data.warren.updateIndex(asset, expectedIndexValueTwo, {from: updaterOne});

        //then
        const iporIndex = await data.warren.getIndex(asset);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        assert(actualIndexValue === expectedIndexValueTwo, `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValueOne}`);
    });

    it('should calculate initial Interest Bearing Token Price', async () => {
        //given
        let asset = testData.tokenUsdt.address;
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let iporIndexValue = BigInt("500000000");

        //when
        await data.warren.updateIndex(asset, iporIndexValue, {from: updaterOne});

        //then
        const iporIndex = await data.warren.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        assert(actualIbtPrice === testUtils.TC_IBT_PRICE_DAI_6DEC,
            `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${testUtils.TC_IBT_PRICE_DAI_6DEC}`);
        assert(actualIndexValue === iporIndexValue, `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporIndexValue}`);

    });

    it('should calculate next Interest Bearing Token Price - one year period', async () => {
        //given
        let asset = testData.tokenUsdt.address;
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let updateDate = Math.floor(Date.now() / 1000);
        await data.warren.test_updateIndex(asset, testUtils.PERCENTAGE_5_6DEC, updateDate, {from: updaterOne});
        let updateDateSecond = updateDate + YEAR_IN_SECONDS;

        let iporIndexSecondValue = BigInt("51000");

        //when
        await data.warren.test_updateIndex(asset, iporIndexSecondValue, updateDateSecond, {from: updaterOne});

        //then
        const iporIndex = await data.warren.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);
        let expectedIbtPrice = BigInt("1050000");

        assert(actualIbtPrice === expectedIbtPrice, `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`);
        assert(actualIndexValue === iporIndexSecondValue, `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexSecondValue}`);

    });

    it('should calculate next Interest Bearing Token Price - one month period', async () => {
        //given
        let asset = testData.tokenUsdt.address;
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        await data.warren.test_updateIndex(asset, testUtils.PERCENTAGE_5_6DEC, updateDate, {from: updaterOne});
        updateDate = updateDate + MONTH_IN_SECONDS;
        let iporIndexSecondValue = testUtils.PERCENTAGE_6_6DEC;

        //when
        await data.warren.test_updateIndex(asset, iporIndexSecondValue, updateDate, {from: updaterOne});

        //then
        const iporIndex = await data.warren.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        let expectedIbtPrice = BigInt("1004110");

        assert(actualIbtPrice === expectedIbtPrice,
            `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`);

        assert(actualIndexValue === iporIndexSecondValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexSecondValue}`);

    });

    it('should calculate next after next Interest Bearing Token Price - half year and three months snapshots', async () => {
        //given
        let asset = testData.tokenUsdt.address;
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let updateDate = Math.floor(Date.now() / 1000);
        await data.warren.test_updateIndex(asset, testUtils.PERCENTAGE_5_6DEC, updateDate, {from: updaterOne});
        updateDate = updateDate + YEAR_IN_SECONDS / 2;
        await data.warren.test_updateIndex(asset, testUtils.PERCENTAGE_6_6DEC, updateDate, {from: updaterOne});
        updateDate = updateDate + YEAR_IN_SECONDS / 4;

        let iporIndexThirdValue = testUtils.PERCENTAGE_7_18DEC;

        //when
        await data.warren.test_updateIndex(asset, iporIndexThirdValue, updateDate, {from: updaterOne});

        //then
        const iporIndex = await data.warren.getIndex(asset);

        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        let expectedIbtPrice = BigInt("1040000");

        assert(actualIbtPrice === expectedIbtPrice, `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`);
        assert(actualIndexValue === iporIndexThirdValue, `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexThirdValue}`);

    });

    it('should NOT update IPOR Index - wrong input arrays', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let assets = [testData.tokenUsdc.address, testData.tokenDai.address];
        let indexValues = [BigInt("50000000000000000")];

        await testUtils.assertError(
            //when
            data.warren.test_updateIndexes(assets, indexValues, updateDate, {from: updaterOne}),
            //then
            'IPOR_18'
        );
    });

    it('should NOT update IPOR Index - Accrue timestamp lower than current ipor index timestamp', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let assets = [testData.tokenUsdc.address, testData.tokenDai.address];
        let indexValues = [BigInt("50000000000000000"), BigInt("50000000000000000")];
        await data.warren.test_updateIndexes(assets, indexValues, updateDate, {from: updaterOne})

        let wrongUpdateDate = updateDate - 1;

        //when
        await testUtils.assertError(
            //when
            data.warren.test_updateIndexes(assets, indexValues, wrongUpdateDate, {from: updaterOne}),
            //then
            'IPOR_27'
        );
    });

    it('should update IPOR Index - correct input arrays', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let assets = [testData.tokenUsdc.address, testData.tokenDai.address];
        let indexValues = [testUtils.PERCENTAGE_8_18DEC, testUtils.PERCENTAGE_7_18DEC];

        //when
        await data.warren.test_updateIndexes(assets, indexValues, updateDate, {from: updaterOne})

        //then
        for (let i = 0; i < assets.length; i++) {
            const iporIndex = await data.warren.getIndex(assets[i]);
            let actualIndexValue = BigInt(iporIndex.indexValue);
            assert(actualIndexValue === indexValues[i], `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${indexValues[i]}`);
        }
    });

    it('should calculate initial Exponential Moving Average - simple case 1', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let assets = [testData.tokenDai.address];
        let indexValues = [testUtils.PERCENTAGE_7_18DEC];
        let expectedExpoMovingAverage = testUtils.PERCENTAGE_7_18DEC;
        //when
        await data.warren.test_updateIndexes(assets, indexValues, updateDate, {from: updaterOne})

        //then
        const iporIndex = await data.warren.getIndex(assets[0]);
        let actualExponentialMovingAverage = BigInt(await iporIndex.exponentialMovingAverage);
        assert(actualExponentialMovingAverage === expectedExpoMovingAverage,
            `Actual exponential moving average is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`);

    });


    it('should calculate initial Exponential Moving Average - 2x IPOR Index updates - 18 decimals', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let assets = [testData.tokenDai.address];
        let firstIndexValues = [testUtils.PERCENTAGE_7_18DEC];
        let secondIndexValues = [testUtils.PERCENTAGE_50_18DEC];
        let expectedExpoMovingAverage = BigInt("113000000000000000");
        //when
        await data.warren.test_updateIndexes(assets, firstIndexValues, updateDate, {from: updaterOne})
        await data.warren.test_updateIndexes(assets, secondIndexValues, updateDate, {from: updaterOne})

        //then
        const iporIndex = await data.warren.getIndex(assets[0]);
        let actualExponentialMovingAverage = BigInt(await iporIndex.exponentialMovingAverage);
        assert(actualExponentialMovingAverage === expectedExpoMovingAverage,
            `Actual exponential moving average for asset ${assets[0]} is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`);

    });

    it('should calculate initial Exponential Moving Average - 2x IPOR Index updates - 6 decimals', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(updaterOne);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let assets = [testData.tokenUsdc.address];
        let firstIndexValues = [testUtils.PERCENTAGE_7_6DEC];
        let secondIndexValues = [testUtils.PERCENTAGE_50_6DEC];
        let expectedExpoMovingAverage = BigInt("113000");
        //when
        await data.warren.test_updateIndexes(assets, firstIndexValues, updateDate, {from: updaterOne})
        await data.warren.test_updateIndexes(assets, secondIndexValues, updateDate, {from: updaterOne})

        //then
        const iporIndex = await data.warren.getIndex(assets[0]);
        let actualExponentialMovingAverage = BigInt(await iporIndex.exponentialMovingAverage);
        assert(actualExponentialMovingAverage === expectedExpoMovingAverage,
            `Actual exponential moving average for asset ${assets[0]} is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`);

    });

    //TODO: add test when transfer ownership and Warren still works properly
    //TODO: add tests for pausable methods
});
