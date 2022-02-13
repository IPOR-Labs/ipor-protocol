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
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_6DEC,
    PERCENTAGE_6_18DEC,
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
    });

    beforeEach(async () => {
        testData = await prepareTestData(
            [admin, userOne, userTwo, userThree],
            ["USDC", "USDT", "DAI"],
            data,
            0
        );
    });

    it("should NOT update IPOR Index, because sender is not an updater", async () => {
        await assertError(
            testData.warren
                .connect(userThree)
                .updateIndex(testData.tokenUsdt.address, 123),
            "IPOR_2"
        );
    });

    it("should NOT update IPOR Index because Warren is not on list of updaters", async () => {
        //given
        await testData.warren.removeUpdater(testData.warren.address);

        await assertError(
            //when
            testData.warren
                .connect(userTwo)
                .updateIndex(testData.tokenUsdt.address, 123),
            //then
            "IPOR_2"
        );
    });

    it("should update IPOR Index", async () => {
        //given
        const asset = testData.tokenDai.address;
        const expectedIndexValue = BigInt(1e20);
        await testData.warren.addUpdater(userOne.address);

        //when
        await testData.warren
            .connect(userOne)
            .updateIndex(asset, expectedIndexValue);

        //then
        const iporIndex = await testData.warren.getIndex(asset);
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
        //given
        await testData.warren.addUpdater(userOne.address);
        const updateDate = Math.floor(Date.now() / 1000);
        const expectedIporIndexValue = BigInt("70000000000000000");
        const assets = [
            testData.tokenUsdc.address,
            testData.tokenDai.address,
            testData.tokenUsdt.address,
        ];
        const indexValues = [
            BigInt("70000000000000000"),
            BigInt("70000000000000000"),
            BigInt("70000000000000000"),
        ];

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndexes(assets, indexValues, updateDate);

        //then
        const iporIndex = await testData.warren
            .connect(userOne)
            .getIndex(testData.tokenDai.address);
        const actualIndexValue = BigInt(iporIndex.indexValue);

        expect(actualIndexValue).to.be.eql(expectedIporIndexValue);
    });

    it("should NOT add IPOR Index Updater", async () => {
        await assertError(
            testData.warren.connect(userThree).addUpdater(userTwo.address),
            "Ownable: caller is not the owner"
        );
    });

    it("should remove IPOR Index Updater", async () => {
        await testData.warren.addUpdater(userOne.address);
        await testData.warren.removeUpdater(userOne.address);

        await assertError(
            //when
            testData.warren
                .connect(userOne)
                .updateIndex(testData.tokenUsdt.address, 123),
            //then
            "IPOR_2"
        );
    });

    it("should NOT remove IPOR Index Updater", async () => {
        await assertError(
            testData.warren.connect(userThree).removeUpdater(userTwo.address),
            "Ownable: caller is not the owner"
        );
    });

    it("should update existing IPOR Index", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        const expectedIndexValueOne = BigInt("123000000000000000");
        const expectedIndexValueTwo = BigInt("321000000000000000");
        await testData.warren.addUpdater(userOne.address);

        //when
        await testData.warren
            .connect(userOne)
            .updateIndex(asset, expectedIndexValueOne);
        await testData.warren
            .connect(userOne)
            .updateIndex(asset, expectedIndexValueTwo);

        //then
        const iporIndex = await testData.warren.getIndex(asset);
        const actualIndexValue = BigInt(iporIndex.indexValue);

        expect(
            actualIndexValue,
            `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValueOne}`
        ).to.be.eql(expectedIndexValueTwo);
    });

    it("should calculate initial Interest Bearing Token Price", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        await testData.warren.addUpdater(userOne.address);
        const iporIndexValue = BigInt("500000000000000000000");

        //when
        await testData.warren
            .connect(userOne)
            .updateIndex(asset, iporIndexValue);

        //then
        const iporIndex = await testData.warren.getIndex(asset);
        const actualIbtPrice = BigInt(iporIndex.ibtPrice);
        const actualIndexValue = BigInt(iporIndex.indexValue);

        expect(
            actualIbtPrice,
            `Actual Interest Bearing Token Price is incorrect ${actualIbtPrice}, expected ${TC_IBT_PRICE_DAI_6DEC}`
        ).to.be.eql(TC_IBT_PRICE_DAI_18DEC);
        expect(
            actualIndexValue,
            `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${iporIndexValue}`
        ).to.be.eql(iporIndexValue);
    });

    it("should calculate next Interest Bearing Token Price - one year period", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        await testData.warren.addUpdater(userOne.address);
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);
        const updateDateSecond = updateDate + YEAR_IN_SECONDS;

        const iporIndexSecondValue = BigInt("51000000000000000");

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, iporIndexSecondValue, updateDateSecond);

        //then
        const iporIndex = await testData.warren.getIndex(asset);
        const actualIbtPrice = BigInt(iporIndex.ibtPrice);
        const actualIndexValue = BigInt(iporIndex.indexValue);
        const expectedIbtPrice = BigInt("1050000000000000000");

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
        await testData.warren.addUpdater(userOne.address);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);
        updateDate = updateDate + MONTH_IN_SECONDS;
        const iporIndexSecondValue = PERCENTAGE_6_6DEC;

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, iporIndexSecondValue, updateDate);

        //then
        const iporIndex = await testData.warren.getIndex(asset);
        const actualIbtPrice = BigInt(iporIndex.ibtPrice);
        const actualIndexValue = BigInt(iporIndex.indexValue);

        const expectedIbtPrice = BigInt("1004109589041095890");

        expect(
            actualIbtPrice,
            `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`
        ).to.be.eql(expectedIbtPrice);

        expect(
            actualIndexValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexSecondValue}`
        ).to.be.eql(iporIndexSecondValue);
    });

    it("should calculate DIFFERENT Interest Bearing Token Price  - ONE SECOND period, same IPOR Index value, 6 decimals asset", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warren.addUpdater(userOne.address);

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);

        const actualFirstIporIndex = await testData.warren.getIndex(asset);
        const actualFirstIbtPrice = BigInt(actualFirstIporIndex.ibtPrice);
        const actualFirstIndexValue = BigInt(actualFirstIporIndex.indexValue);

        updateDate = updateDate + 1;

        const iporIndexSecondValue = PERCENTAGE_5_18DEC;

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, iporIndexSecondValue, updateDate);

        //then
        const actualSecondIporIndex = await testData.warren.getIndex(asset);
        const actualSecondIbtPrice = BigInt(actualSecondIporIndex.ibtPrice);
        const actualSecondIndexValue = BigInt(actualSecondIporIndex.indexValue);

        expect(
            actualFirstIbtPrice,
            `Actual Interest Bearing Token Price should be different than previous one, actual: ${actualSecondIbtPrice}, expected: ${actualFirstIbtPrice}`
        ).to.not.equal(actualSecondIbtPrice);

        expect(
            actualSecondIndexValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualSecondIndexValue}, expected: ${actualFirstIndexValue}`
        ).to.equal(actualFirstIndexValue);
    });

    it("should calculate DIFFERENT Interest Bearing Token Price  - ONE SECOND period, same IPOR Index value, 18 decimals asset", async () => {
        //given
        const asset = testData.tokenDai.address;
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warren.addUpdater(userOne.address);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);

        const actualFirstIporIndex = await testData.warren.getIndex(asset);
        const actualFirstIbtPrice = BigInt(actualFirstIporIndex.ibtPrice);
        const actualFirstIndexValue = BigInt(actualFirstIporIndex.indexValue);

        updateDate = updateDate + 1;

        const iporIndexSecondValue = PERCENTAGE_5_18DEC;

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, iporIndexSecondValue, updateDate);

        //then
        const actualSecondIporIndex = await testData.warren.getIndex(asset);
        const actualSecondIbtPrice = BigInt(actualSecondIporIndex.ibtPrice);
        const actualSecondIndexValue = BigInt(actualSecondIporIndex.indexValue);

        expect(
            actualFirstIbtPrice,
            `Actual Interest Bearing Token Price should be different than previous one, actual: ${actualSecondIbtPrice}, expected: ${actualFirstIbtPrice}`
        ).to.not.equal(actualSecondIbtPrice);

        expect(
            actualSecondIndexValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualSecondIndexValue}, expected: ${actualFirstIndexValue}`
        ).to.equal(actualFirstIndexValue);
    });

    it("should calculate next after next Interest Bearing Token Price - half year and three months snapshots", async () => {
        //given
        const asset = testData.tokenUsdt.address;
        await testData.warren.addUpdater(userOne.address);
        let updateDate = Math.floor(Date.now() / 1000);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);
        updateDate = updateDate + YEAR_IN_SECONDS / 2;
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, PERCENTAGE_6_18DEC, updateDate);
        updateDate = updateDate + YEAR_IN_SECONDS / 4;

        let iporIndexThirdValue = PERCENTAGE_7_18DEC;

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(asset, iporIndexThirdValue, updateDate);

        //then
        const iporIndex = await testData.warren.getIndex(asset);

        const actualIbtPrice = BigInt(iporIndex.ibtPrice);
        const actualIndexValue = BigInt(iporIndex.indexValue);
        const expectedIbtPrice = BigInt("1040000000000000000");

        expect(
            actualIbtPrice,
            `Actual Interest Bearing Token Price is incorrect, actual: ${actualIbtPrice}, expected: ${expectedIbtPrice}`
        ).to.be.eql(expectedIbtPrice);
        expect(
            actualIndexValue,
            `Actual IPOR Index Value is incorrect, actual: ${actualIndexValue}, expected: ${iporIndexThirdValue}`
        ).to.be.eql(iporIndexThirdValue);
    });

    it("should NOT update IPOR Index - asset not supported", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warren.addUpdater(userOne.address);

        const assets = [userOne.address];
        const indexValues = [BigInt("50000000000000000")];

        await assertError(
            //when
            testData.warren
                .connect(userOne)
                .itfUpdateIndexes(assets, indexValues, updateDate),
            //then
            "IPOR_39"
        );
    });

    it("should NOT update IPOR Index - wrong input arrays", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warren.addUpdater(userOne.address);

        const assets = [testData.tokenUsdc.address, testData.tokenDai.address];
        const indexValues = [BigInt("50000000000000000")];

        await assertError(
            //when
            testData.warren
                .connect(userOne)
                .itfUpdateIndexes(assets, indexValues, updateDate),
            //then
            "IPOR_18"
        );
    });

    it("should NOT update IPOR Index - Accrue timestamp lower than current ipor index timestamp", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warren.addUpdater(userOne.address);
        const assets = [testData.tokenUsdc.address, testData.tokenDai.address];
        const indexValues = [
            BigInt("50000000000000000"),
            BigInt("50000000000000000"),
        ];
        await testData.warren
            .connect(userOne)
            .itfUpdateIndexes(assets, indexValues, updateDate);

        const wrongUpdateDate = updateDate - 1;

        //when
        await assertError(
            //when
            testData.warren
                .connect(userOne)
                .itfUpdateIndexes(assets, indexValues, wrongUpdateDate),
            //then
            "IPOR_27"
        );
    });

    it("should update IPOR Index - correct input arrays", async () => {
        //given
        const updateDate = Math.floor(Date.now() / 1000);
        await testData.warren.addUpdater(userOne.address);

        const assets = [
            testData.tokenUsdc.address,
            testData.tokenDai.address,
            testData.tokenUsdt.address,
        ];
        const indexValues = [
            PERCENTAGE_8_18DEC,
            PERCENTAGE_7_18DEC,
            PERCENTAGE_5_18DEC,
        ];

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndexes(assets, indexValues, updateDate);

        //then
        for (let i = 0; i < assets.length; i++) {
            const iporIndex = await testData.warren.getIndex(assets[i]);
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
        await testData.warren.addUpdater(userOne.address);
        const assets = [
            testData.tokenDai.address,
            testData.tokenUsdc.address,
            testData.tokenUsdt.address,
        ];
        const indexValues = [
            PERCENTAGE_7_18DEC,
            PERCENTAGE_7_18DEC,
            PERCENTAGE_7_18DEC,
        ];
        const expectedExpoMovingAverage = PERCENTAGE_7_18DEC;
        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndexes(assets, indexValues, updateDate);

        //then
        const iporIndex = await testData.warren.getIndex(assets[0]);
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
        await testData.warren.addUpdater(userOne.address);
        const assets = [
            testData.tokenDai.address,
            testData.tokenUsdt.address,
            testData.tokenUsdc.address,
        ];
        const firstIndexValues = [
            PERCENTAGE_7_18DEC,
            PERCENTAGE_7_18DEC,
            PERCENTAGE_7_18DEC,
        ];
        const secondIndexValues = [
            PERCENTAGE_50_18DEC,
            PERCENTAGE_50_18DEC,
            PERCENTAGE_50_18DEC,
        ];
        const expectedExpoMovingAverage = BigInt("113000000000000000");

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndexes(assets, firstIndexValues, updateDate);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndexes(assets, secondIndexValues, updateDate);

        //then
        const iporIndex = await testData.warren.getIndex(assets[0]);
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
        await testData.warren.addUpdater(userOne.address);
        const assets = [
            testData.tokenUsdc.address,
            testData.tokenDai.address,
            testData.tokenUsdt.address,
        ];
        const firstIndexValues = [
            PERCENTAGE_7_6DEC,
            PERCENTAGE_7_6DEC,
            PERCENTAGE_7_6DEC,
        ];
        const secondIndexValues = [
            PERCENTAGE_50_6DEC,
            PERCENTAGE_50_6DEC,
            PERCENTAGE_50_6DEC,
        ];
        const expectedExpoMovingAverage = BigInt("113000");

        //when
        await testData.warren
            .connect(userOne)
            .itfUpdateIndexes(assets, firstIndexValues, updateDate);
        await testData.warren
            .connect(userOne)
            .itfUpdateIndexes(assets, secondIndexValues, updateDate);

        //then
        const iporIndex = await testData.warren.getIndex(assets[0]);
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
