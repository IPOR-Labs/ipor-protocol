const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
    assertError,
    prepareData,
    prepareTestData,
    getLibraries,
} = require("./Utils");

const {
    TC_IBT_PRICE_DAI_18DEC,
    TC_IBT_PRICE_DAI_6DEC,
    PERCENTAGE_5_6DEC,
    PERCENTAGE_6_6DEC,
    PERCENTAGE_7_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_50_6DEC,
    PERCENTAGE_7_6DEC,
} = require("./Const.js");

const YEAR_IN_SECONDS = 31536000;
const MONTH_IN_SECONDS = 60 * 60 * 24 * 30;

describe("Warren", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let data = null;
    let testData;
    let libraries;
    let warrenDevToolDataProvider = null;

    before(async () => {
        libraries = await getLibraries();

        [admin, userOne, userTwo, userThree, liquidityProvider] =
            await ethers.getSigners();
        data = await prepareData(libraries, [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
        ]);

        const WarrenDevToolDataProvider = await ethers.getContractFactory(
            "WarrenDevToolDataProvider"
        );
        warrenDevToolDataProvider = await WarrenDevToolDataProvider.deploy(
            data.iporConfiguration.address
        );
        await warrenDevToolDataProvider.deployed();
    });

    beforeEach(async () => {
        testData = await prepareTestData(
            [admin, userOne, userTwo, userThree],
            ["USDC", "USDT", "DAI"],
            data,
            libraries
        );
    });

    it("should NOT update IPOR Index, because sender is not an updater", async () => {
        await assertError(
            data.warren
                .connect(userThree)
                .updateIndex(testData.tokenUsdt.address, 123),
            "IPOR_2"
        );
    });

    it("should NOT update IPOR Index because Warren is not on list of updaters", async () => {
        //given
        await testData.warrenStorage.removeUpdater(data.warren.address);

        await assertError(
            //when
            data.warren
                .connect(userTwo)
                .updateIndex(testData.tokenUsdt.address, 123),
            //then
            "IPOR_2"
        );
        await testData.warrenStorage.addUpdater(data.warren.address);
    });

    it("should update IPOR Index", async () => {
        //given
        const asset = testData.tokenDai.address;
        const expectedIndexValue = BigInt(1e20);
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);

        //when
        await data.warren
            .connect(userOne)
            .updateIndex(asset, expectedIndexValue);

        //then
        const iporIndex = await data.warren.getIndex(asset);
        const actualIndexValue = BigInt(iporIndex.indexValue);
        const actualIbtPrice = BigInt(iporIndex.ibtPrice);

        expect(
            expectedIndexValue,
            `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValue}`
        ).to.be.eql(actualIndexValue);
        expect(
            TC_IBT_PRICE_DAI_18DEC,
            `Incorrect Interest Bearing Token Price ${actualIbtPrice}, expected ${TC_IBT_PRICE_DAI_18DEC}`
        ).to.be.eql(actualIbtPrice);
    });

    it("should add IPOR Index Updater", async () => {
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const updaters = await testData.warrenStorage.getUpdaters();
        expect(
            updaters.includes(userOne.address),
            `Updater ${userOne.address} should exist in list of updaters in IPOR Oracle, but not exists`
        ).to.be.true;
    });

    it("should NOT add IPOR Index Updater", async () => {
        await assertError(
            testData.warrenStorage
                .connect(userThree)
                .addUpdater(userTwo.address),
            "Ownable: caller is not the owner"
        );
    });

    it("should remove IPOR Index Updater", async () => {
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.removeUpdater(userOne.address);
        const updaters = await testData.warrenStorage.getUpdaters();
        expect(
            updaters.includes(userOne.address),
            `Updater ${userOne.address} should not exist in list of updaters in IPOR Oracle, but exists`
        ).to.be.false;
    });

    it("should NOT remove IPOR Index Updater", async () => {
        await assertError(
            testData.warrenStorage
                .connect(userThree)
                .removeUpdater(userTwo.address),
            "Ownable: caller is not the owner"
        );
    });

    it("should retrieve list of IPOR Indexes", async () => {
        //given
        const expectedAssetOne = testData.tokenUsdt.address;
        const expectedAssetSymbolOne = "USDT";
        const expectedAssetTwo = testData.tokenDai.address;
        const expectedAssetSymbolTwo = "DAI";
        const expectedIporIndexesSize = 2;
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        await data.warren
            .connect(userOne)
            .updateIndex(expectedAssetOne, BigInt(1e8));
        await data.warren
            .connect(userOne)
            .updateIndex(expectedAssetTwo, BigInt(1e20));

        //when
        const iporIndexes = await warrenDevToolDataProvider.getIndexes();

        //then
        expect(
            expectedIporIndexesSize,
            `Incorrect IPOR indexes size ${iporIndexes.length}, expected ${expectedIporIndexesSize}`
        ).to.be.eql(iporIndexes.length);
        expect(
            expectedAssetSymbolOne,
            `Incorrect asset on first position in indexes ${iporIndexes[0].asset}, expected ${expectedAssetOne}`
        ).to.be.eql(iporIndexes[0].asset);
        expect(
            expectedAssetSymbolTwo,
            `Incorrect asset on second position in indexes ${iporIndexes[1].asset}, expected ${expectedAssetTwo}`
        ).to.be.eql(iporIndexes[1].asset);
    });

    it("should update existing IPOR Index", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        const expectedIndexValueOne = BigInt("123000000000000000000");
        const expectedIndexValueTwo = BigInt("321000000000000000000");
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);

        //when
        await data.warren
            .connect(userOne)
            .updateIndex(asset, expectedIndexValueOne);
        await data.warren
            .connect(userOne)
            .updateIndex(asset, expectedIndexValueTwo);

        //then
        const iporIndex = await data.warren.getIndex(asset);
        const actualIndexValue = BigInt(iporIndex.indexValue);

        expect(
            actualIndexValue,
            `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValueOne}`
        ).to.be.eql(expectedIndexValueTwo);
    });

    it("should calculate initial Interest Bearing Token Price", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const iporIndexValue = BigInt("500000000");

        //when
        await data.warren.connect(userOne).updateIndex(asset, iporIndexValue);

        //then
        const iporIndex = await data.warren.getIndex(asset);
        const actualIbtPrice = BigInt(iporIndex.ibtPrice);
        const actualIndexValue = BigInt(iporIndex.indexValue);

        expect(
            actualIbtPrice,
            `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${TC_IBT_PRICE_DAI_6DEC}`
        ).to.be.eql(TC_IBT_PRICE_DAI_6DEC);
        expect(
            actualIndexValue,
            `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporIndexValue}`
        ).to.be.eql(iporIndexValue);
    });

    it("should calculate next Interest Bearing Token Price - one year period", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const updateDate = Math.floor(Date.now() / 1000);
        await data.warren
            .connect(userOne)
            .test_updateIndex(asset, PERCENTAGE_5_6DEC, updateDate);
        const updateDateSecond = updateDate + YEAR_IN_SECONDS;

        const iporIndexSecondValue = BigInt("51000");

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndex(asset, iporIndexSecondValue, updateDateSecond);

        //then
        const iporIndex = await data.warren.getIndex(asset);
        const actualIbtPrice = BigInt(iporIndex.ibtPrice);
        const actualIndexValue = BigInt(iporIndex.indexValue);
        const expectedIbtPrice = BigInt("1050000");

        expect(
            actualIbtPrice,
            `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`
        ).to.be.eql(expectedIbtPrice);
        expect(
            actualIndexValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexSecondValue}`
        ).to.be.eql(iporIndexSecondValue);
    });

    it("should calculate next Interest Bearing Token Price - one month period", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        await data.warren
            .connect(userOne)
            .test_updateIndex(asset, PERCENTAGE_5_6DEC, updateDate);
        updateDate = updateDate + MONTH_IN_SECONDS;
        const iporIndexSecondValue = PERCENTAGE_6_6DEC;

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndex(asset, iporIndexSecondValue, updateDate);

        //then
        const iporIndex = await data.warren.getIndex(asset);
        const actualIbtPrice = BigInt(iporIndex.ibtPrice);
        const actualIndexValue = BigInt(iporIndex.indexValue);

        const expectedIbtPrice = BigInt("1004110");

        expect(
            actualIbtPrice,
            `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`
        ).to.be.eql(expectedIbtPrice);

        expect(
            actualIndexValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexSecondValue}`
        ).to.be.eql(iporIndexSecondValue);
    });

    it("should calculate next after next Interest Bearing Token Price - half year and three months snapshots", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        let updateDate = Math.floor(Date.now() / 1000);
        await data.warren
            .connect(userOne)
            .test_updateIndex(asset, PERCENTAGE_5_6DEC, updateDate);
        updateDate = updateDate + YEAR_IN_SECONDS / 2;
        await data.warren
            .connect(userOne)
            .test_updateIndex(asset, PERCENTAGE_6_6DEC, updateDate);
        updateDate = updateDate + YEAR_IN_SECONDS / 4;

        let iporIndexThirdValue = PERCENTAGE_7_18DEC;

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndex(asset, iporIndexThirdValue, updateDate);

        //then
        const iporIndex = await data.warren.getIndex(asset);

        const actualIbtPrice = BigInt(iporIndex.ibtPrice);
        const actualIndexValue = BigInt(iporIndex.indexValue);
        const expectedIbtPrice = BigInt("1040000");

        expect(
            actualIbtPrice,
            `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`
        ).to.be.eql(expectedIbtPrice);
        expect(
            actualIndexValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexThirdValue}`
        ).to.be.eql(iporIndexThirdValue);
    });

    it("should NOT update IPOR Index - wrong input arrays", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const assets = [testData.tokenUsdc.address, testData.tokenDai.address];
        const indexValues = [BigInt("50000000000000000")];

        await assertError(
            //when
            data.warren
                .connect(userOne)
                .test_updateIndexes(assets, indexValues, updateDate),
            //then
            "IPOR_18"
        );
    });

    it("should NOT update IPOR Index - Accrue timestamp lower than current ipor index timestamp", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const assets = [testData.tokenUsdc.address, testData.tokenDai.address];
        const indexValues = [
            BigInt("50000000000000000"),
            BigInt("50000000000000000"),
        ];
        await data.warren
            .connect(userOne)
            .test_updateIndexes(assets, indexValues, updateDate);

        const wrongUpdateDate = updateDate - 1;

        //when
        await assertError(
            //when
            data.warren
                .connect(userOne)
                .test_updateIndexes(assets, indexValues, wrongUpdateDate),
            //then
            "IPOR_27"
        );
    });

    it("should update IPOR Index - correct input arrays", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const assets = [testData.tokenUsdc.address, testData.tokenDai.address];
        const indexValues = [PERCENTAGE_8_18DEC, PERCENTAGE_7_18DEC];

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndexes(assets, indexValues, updateDate);

        //then
        for (let i = 0; i < assets.length; i++) {
            const iporIndex = await data.warren.getIndex(assets[i]);
            const actualIndexValue = BigInt(iporIndex.indexValue);
            expect(
                actualIndexValue,
                `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${indexValues[i]}`
            ).to.be.eql(indexValues[i]);
        }
    });

    it("should calculate initial Exponential Moving Average - simple case 1", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const assets = [testData.tokenDai.address];
        const indexValues = [PERCENTAGE_7_18DEC];
        const expectedExpoMovingAverage = PERCENTAGE_7_18DEC;
        //when
        await data.warren
            .connect(userOne)
            .test_updateIndexes(assets, indexValues, updateDate);

        //then
        const iporIndex = await data.warren.getIndex(assets[0]);
        const actualExponentialMovingAverage = BigInt(
            await iporIndex.exponentialMovingAverage
        );
        expect(
            actualExponentialMovingAverage,
            `Actual exponential moving average is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`
        ).to.be.eql(expectedExpoMovingAverage);
    });

    it("should calculate initial Exponential Moving Average - 2x IPOR Index updates - 18 decimals", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const assets = [testData.tokenDai.address];
        const firstIndexValues = [PERCENTAGE_7_18DEC];
        const secondIndexValues = [PERCENTAGE_50_18DEC];
        const expectedExpoMovingAverage = BigInt("113000000000000000");

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndexes(assets, firstIndexValues, updateDate);
        await data.warren
            .connect(userOne)
            .test_updateIndexes(assets, secondIndexValues, updateDate);

        //then
        const iporIndex = await data.warren.getIndex(assets[0]);
        const actualExponentialMovingAverage = BigInt(
            await iporIndex.exponentialMovingAverage
        );
        expect(
            actualExponentialMovingAverage,
            `Actual exponential moving average for asset ${assets[0]} is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`
        ).to.be.eql(expectedExpoMovingAverage);
    });

    it("should calculate initial Exponential Moving Average - 2x IPOR Index updates - 6 decimals", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warrenStorage.addUpdater(userOne.address);
        await testData.warrenStorage.addUpdater(data.warren.address);
        const assets = [testData.tokenUsdc.address];
        const firstIndexValues = [PERCENTAGE_7_6DEC];
        const secondIndexValues = [PERCENTAGE_50_6DEC];
        const expectedExpoMovingAverage = BigInt("113000");

        //when
        await data.warren
            .connect(userOne)
            .test_updateIndexes(assets, firstIndexValues, updateDate);
        await data.warren
            .connect(userOne)
            .test_updateIndexes(assets, secondIndexValues, updateDate);

        //then
        const iporIndex = await data.warren.getIndex(assets[0]);
        let actualExponentialMovingAverage = BigInt(
            await iporIndex.exponentialMovingAverage
        );
        expect(
            actualExponentialMovingAverage,
            `Actual exponential moving average for asset ${assets[0]} is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`
        ).to.be.eql(expectedExpoMovingAverage);
    });

    //TODO: add test when transfer ownership and Warren still works properly
    //TODO: add tests for pausable methods
});
