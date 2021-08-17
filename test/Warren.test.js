const utils = require("./TestUtils.js");
const {time} = require('@openzeppelin/test-helpers');
const IporLogic = artifacts.require('IporLogic');
const TestWarrenProxy = artifacts.require('TestWarrenProxy');
const WARREN_5_PERCENTAGE = BigInt("50000000000000000");
const WARREN_6_PERCENTAGE = BigInt("60000000000000000");
const WARREN_7_PERCENTAGE = BigInt("70000000000000000");
const WARREN_8_PERCENTAGE = BigInt("80000000000000000");

contract('Warren', (accounts) => {

    const [admin, updaterOne, updaterTwo, user] = accounts;

    const INITIAL_INTEREST_BEARING_TOKEN_PRICE = BigInt(1e18);
    const YEAR_IN_SECONDS = 31536000;
    const MONTH_IN_SECONDS = 60 * 60 * 24 * 30;

    let warren = null;

    beforeEach(async () => {
        warren = await TestWarrenProxy.new();
    });

    it('should NOT update IPOR Index', async () => {
        await testUtils.assertError(
            warren.updateIndex("ASSET_SYMBOL", 123, {from: updaterOne}),
            'IPOR_2'
        );
    });

    it('should NOT update IPOR Index because input value is too low', async () => {
        await testUtils.assertError(
            warren.updateIndex("USDT", 123, {from: updaterOne}),
            'IPOR_2'
        );
    });

    it('should update IPOR Index', async () => {
        //given
        let asset = "USDT";
        let expectedIndexValue = BigInt(1e20);
        await warren.addUpdater(updaterOne);

        //when
        await warren.updateIndex(asset, expectedIndexValue, {from: updaterOne})

        //then
        const iporIndex = await warren.getIndex(asset);
        let actualIndexValue = BigInt(iporIndex.indexValue);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);

        assert(expectedIndexValue === actualIndexValue,
            `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValue}`);
        assert(INITIAL_INTEREST_BEARING_TOKEN_PRICE == actualIbtPrice,
            `Incorrect Interest Bearing Token Price ${actualIbtPrice}, expected ${INITIAL_INTEREST_BEARING_TOKEN_PRICE}`)
    });

    it('should add IPOR Index Updater', async () => {
        await warren.addUpdater(updaterOne);
        const updaters = await warren.getUpdaters();
        assert(updaters.includes(updaterOne), `Updater ${updaterOne} should exist in list of updaters in IPOR Oracle, but not exists`);
    });

    it('should NOT add IPOR Index Updater', async () => {
        await testUtils.assertError(
            warren.addUpdater(updaterTwo, {from: user}),
            'Ownable: caller is not the owner'
        );
    });

    it('should remove IPOR Index Updater', async () => {
        await warren.addUpdater(updaterOne);
        await warren.removeUpdater(updaterOne);
        const updaters = await warren.getUpdaters();
        assert(!updaters.includes(updaterOne), `Updater ${updaterOne} should not exist in list of updaters in IPOR Oracle, but exists`);
    });

    it('should NOT remove IPOR Index Updater', async () => {
        await testUtils.assertError(
            warren.removeUpdater(updaterTwo, {from: user}),
            'Ownable: caller is not the owner'
        );
    });

    it('should retrieve list of IPOR Indexes', async () => {
        //given
        let expectedAssetOne = "USDT";
        let expectedAssetTwo = "DAI";
        let expectedIporIndexesSize = 2;
        await warren.addUpdater(updaterOne);
        await warren.updateIndex(expectedAssetOne, BigInt(1e20), {from: updaterOne});
        await warren.updateIndex(expectedAssetTwo, BigInt(1e20), {from: updaterOne});

        //when
        const iporIndexes = await warren.getIndexes();

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
        await warren.addUpdater(updaterOne);

        //when
        await warren.updateIndex(asset, expectedIndexValueOne, {from: updaterOne});
        await warren.updateIndex(asset, expectedIndexValueTwo, {from: updaterOne});

        //then
        const iporIndex = await warren.getIndex(asset);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        assert(actualIndexValue === expectedIndexValueTwo, `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValueOne}`);
    });

    it('should calculate initial Interest Bearing Token Price', async () => {
        //given
        let asset = "USDT";
        await warren.addUpdater(updaterOne);
        let iporIndexValue = BigInt("500000000000000000000");

        //when
        await warren.updateIndex(asset, iporIndexValue, {from: updaterOne});

        //then
        const iporIndex = await warren.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        assert(actualIbtPrice === INITIAL_INTEREST_BEARING_TOKEN_PRICE,
            `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${INITIAL_INTEREST_BEARING_TOKEN_PRICE}`);
        assert(actualIndexValue === iporIndexValue, `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporIndexValue}`);

    });

    it('should calculate next Interest Bearing Token Price - one year period', async () => {
        //given
        let asset = "USDT";
        await warren.addUpdater(updaterOne);
        let updateDate = Math.floor(Date.now() / 1000);
        await warren.test_updateIndex(asset, WARREN_5_PERCENTAGE, updateDate, {from: updaterOne});
        let updateDateSecond = updateDate + YEAR_IN_SECONDS;

        let iporIndexSecondValue = BigInt("51000000000000000");

        //when
        await warren.test_updateIndex(asset, iporIndexSecondValue, updateDateSecond, {from: updaterOne});

        //then
        const iporIndex = await warren.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);
        let expectedIbtPrice = BigInt("1050000000000000000");

        assert(actualIbtPrice === expectedIbtPrice, `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`);
        assert(actualIndexValue === iporIndexSecondValue, `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexSecondValue}`);

    });

    it('should calculate next Interest Bearing Token Price - one month period', async () => {
        //given
        let asset = "USDT";
        let updateDate = Math.floor(Date.now() / 1000);
        await warren.addUpdater(updaterOne);
        await warren.test_updateIndex(asset, WARREN_5_PERCENTAGE, updateDate, {from: updaterOne});
        updateDate = updateDate + MONTH_IN_SECONDS;
        let iporIndexSecondValue = WARREN_6_PERCENTAGE;

        //when
        await warren.test_updateIndex(asset, iporIndexSecondValue, updateDate, {from: updaterOne});

        //then
        const iporIndex = await warren.getIndex(asset);
        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        let expectedIbtPrice = BigInt("1004109589041095890");

        assert(actualIbtPrice === expectedIbtPrice,
            `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`);

        assert(actualIndexValue === iporIndexSecondValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexSecondValue}`);

    });

    it('should calculate next after next Interest Bearing Token Price - half year and three months snapshots', async () => {
        //given
        let asset = "USDT";
        await warren.addUpdater(updaterOne);
        let updateDate = Math.floor(Date.now() / 1000);
        await warren.test_updateIndex(asset, WARREN_5_PERCENTAGE, updateDate, {from: updaterOne});
        updateDate = updateDate + YEAR_IN_SECONDS / 2;
        await warren.test_updateIndex(asset, WARREN_6_PERCENTAGE, updateDate, {from: updaterOne});
        updateDate = updateDate + YEAR_IN_SECONDS / 4;

        let iporIndexThirdValue = WARREN_7_PERCENTAGE;

        //when
        await warren.test_updateIndex(asset, iporIndexThirdValue, updateDate, {from: updaterOne});

        //then
        const iporIndex = await warren.getIndex(asset);

        let actualIbtPrice = BigInt(iporIndex.ibtPrice);
        let actualIndexValue = BigInt(iporIndex.indexValue);

        let expectedIbtPrice = BigInt("1040000000000000000");

        assert(actualIbtPrice === expectedIbtPrice, `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`);
        assert(actualIndexValue === iporIndexThirdValue, `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexThirdValue}`);

    });

    it('should NOT update IPOR Index - wrong input arrays', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await warren.addUpdater(updaterOne);
        let assets = ["USDC", "DAI"];
        let indexValues = [BigInt("50000000000000000")];

        await testUtils.assertError(
            //when
            warren.test_updateIndexes(assets, indexValues, updateDate, {from: updaterOne}),
            //then
            'IPOR_18'
        );
    });

    it('should update IPOR Index - correct input arrays', async () => {
        //given
        let updateDate = Math.floor(Date.now() / 1000);
        await warren.addUpdater(updaterOne);
        let assets = ["USDC", "DAI"];
        let indexValues = [WARREN_8_PERCENTAGE, WARREN_7_PERCENTAGE];

        //when
        await warren.test_updateIndexes(assets, indexValues, updateDate, {from: updaterOne})

        //then
        for (let i = 0; i < assets.length; i++) {
            const iporIndex = await warren.getIndex(assets[i]);
            let actualIndexValue = BigInt(iporIndex.indexValue);
            assert(actualIndexValue === indexValues[i], `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${indexValues[i]}`);
        }
    });

});
