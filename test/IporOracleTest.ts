import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N0__01_18DEC,
    PERCENTAGE_100_18DEC,
    TC_IBT_PRICE_DAI_18DEC,
    YEAR_IN_SECONDS,
    PERCENTAGE_5_18DEC,
    TC_IBT_PRICE_DAI_6DEC,
    PERCENTAGE_6_6DEC,
    MONTH_IN_SECONDS,
    N1__0_18DEC,
    PERCENTAGE_7_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_7_6DEC,
    PERCENTAGE_50_6DEC,
} from "./utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "./utils/MiltonUtils";

import { TestData, prepareTestData } from "./utils/DataUtils";
import { MockStanleyCase } from "./utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "./utils/JosephUtils";
import { assertError } from "./utils/AssertUtils";
import { ItfIporOracle, DaiMockedToken, UsdtMockedToken, UsdcMockedToken } from "../types";

const { expect } = chai;

describe("IporOracle", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let testData: TestData;
    let _iporOracle: ItfIporOracle;
    let _tokenDai: DaiMockedToken;
    let _tokenUsdt: UsdtMockedToken;
    let _tokenUsdc: UsdcMockedToken;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    beforeEach(async () => {
        testData = (await prepareTestData(
            [admin, userOne, userTwo, userThree],
            ["USDC", "USDT", "DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        )) as TestData;
        const { iporOracle, tokenUsdt, tokenUsdc, tokenDai } = testData;
        if (tokenUsdt === undefined || tokenUsdc === undefined || tokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        _iporOracle = iporOracle;
        _tokenDai = tokenDai;
        _tokenUsdt = tokenUsdt;
        _tokenUsdc = tokenUsdc;
    });

    it("Should removed asset", async () => {
        await expect(_iporOracle.removeAsset(_tokenDai.address))
            .emit(_iporOracle, "IporIndexRemoveAsset")
            .withArgs(_tokenDai.address);
    });

    it("should Decay Factor be lower than 100%", async () => {
        const decayFactorValue = await _iporOracle.itfGetDecayFactorValue();
        expect(decayFactorValue.lte(PERCENTAGE_100_18DEC)).to.be.true;
    });

    it("should return contract version", async () => {
        const version = await _iporOracle["getVersion()"]();
        // then
        expect(version).to.be.equal(BigNumber.from("1"));
    });

    it("should pause Smart Contract, sender is an admin", async () => {
        //when
        await _iporOracle.addUpdater(await userOne.getAddress());
        await _iporOracle.connect(admin).pause();

        //then
        await assertError(
            _iporOracle.connect(userOne).updateIndex(_tokenUsdt.address, BigNumber.from("123")),
            "Pausable: paused"
        );
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        const assets = [_tokenUsdc.address, _tokenDai.address, _tokenUsdt.address];
        const indexValues = [
            BigNumber.from("7").mul(N0__01_18DEC),
            BigNumber.from("7").mul(N0__01_18DEC),
            BigNumber.from("7").mul(N0__01_18DEC),
        ];

        await _iporOracle.addUpdater(await userOne.getAddress());
        await _iporOracle.connect(admin).pause();

        //when
        await assertError(
            _iporOracle.connect(userOne).updateIndex(_tokenUsdt.address, 123),
            "Pausable: paused"
        );

        await assertError(
            _iporOracle.connect(userOne).updateIndexes(assets, indexValues),
            "Pausable: paused"
        );

        await assertError(
            _iporOracle.connect(admin).addAsset(await userThree.getAddress()),
            "Pausable: paused"
        );

        await assertError(
            _iporOracle.connect(admin).removeAsset(await userThree.getAddress()),
            "Pausable: paused"
        );

        await assertError(
            _iporOracle.connect(admin).addUpdater(await userThree.getAddress()),
            "Pausable: paused"
        );

        await assertError(
            _iporOracle.connect(admin).removeUpdater(await userThree.getAddress()),
            "Pausable: paused"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        const assets = [_tokenUsdc.address, _tokenDai.address, _tokenUsdt.address];
        const indexValues = [
            BigNumber.from("7").mul(N0__01_18DEC),
            BigNumber.from("7").mul(N0__01_18DEC),
            BigNumber.from("7").mul(N0__01_18DEC),
        ];
        const timestamp = BigNumber.from(Math.floor(Date.now() / 1000));

        await _iporOracle.addUpdater(await userOne.getAddress());
        await _iporOracle.connect(admin).pause();

        //when
        await _iporOracle.connect(userOne).getIndex(_tokenUsdt.address);

        await _iporOracle.connect(userOne).getAccruedIndex(timestamp, _tokenUsdt.address);

        await _iporOracle.connect(userOne).calculateAccruedIbtPrice(_tokenUsdt.address, timestamp);

        await _iporOracle.connect(userOne).isUpdater(await userOne.getAddress());
    });

    it("should NOT pause Smart Contract, sender is NOT an admin", async () => {
        //when
        await assertError(
            _iporOracle.connect(userThree).pause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should unpause Smart Contract, sender is an admin", async () => {
        //given

        const assets = [_tokenUsdc.address, _tokenDai.address, _tokenUsdt.address];
        const indexValues = [
            BigNumber.from("7").mul(N0__01_18DEC),
            BigNumber.from("7").mul(N0__01_18DEC),
            BigNumber.from("7").mul(N0__01_18DEC),
        ];
        const expectedIporIndexValue = BigNumber.from("7").mul(N0__01_18DEC);

        await _iporOracle.addUpdater(await userOne.getAddress());
        await _iporOracle.connect(admin).pause();

        await assertError(
            _iporOracle.connect(userOne).updateIndexes(assets, indexValues),
            "Pausable: paused"
        );

        //when
        await _iporOracle.connect(admin).unpause();
        await _iporOracle.connect(userOne).updateIndexes(assets, indexValues);

        //then
        const iporIndex = await _iporOracle.connect(userOne).getIndex(_tokenDai.address);
        const actualIndexValue = BigNumber.from(iporIndex.indexValue);

        expect(actualIndexValue).to.be.eql(expectedIporIndexValue);
    });

    it("should NOT unpause Smart Contract, sender is NOT an admin", async () => {
        //given
        await _iporOracle.connect(admin).pause();

        //when
        await assertError(
            _iporOracle.connect(userThree).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await _iporOracle.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await _iporOracle.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await _iporOracle.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            _iporOracle.connect(userThree).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await _iporOracle.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await assertError(
            _iporOracle.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await _iporOracle.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await _iporOracle.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            _iporOracle.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const expectedNewOwner = userTwo;

        await _iporOracle.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await _iporOracle.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            _iporOracle.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const expectedNewOwner = userTwo;

        await _iporOracle.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //when
        await _iporOracle.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await _iporOracle.connect(userOne).owner();
        expect(await admin.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should Decay Factor be lower than 100%", async () => {
        const decayFactorValue = await _iporOracle.itfGetDecayFactorValue();
        expect(decayFactorValue.lte(PERCENTAGE_100_18DEC)).to.be.true;
    });

    it("should NOT update IPOR Index, because sender is not an updater", async () => {
        await assertError(
            _iporOracle.connect(userThree).updateIndex(_tokenUsdt.address, 123),
            "IPOR_202"
        );
    });

    it("should NOT update IPOR Index because _iporOracle is not on list of updaters", async () => {
        //given
        await _iporOracle.removeUpdater(_iporOracle.address);

        await assertError(
            //when
            _iporOracle.connect(userTwo).updateIndex(_tokenUsdt.address, 123),
            //then
            "IPOR_202"
        );
    });

    it("should update IPOR Index", async () => {
        //given
        const asset = _tokenDai.address;
        const expectedIndexValue = BigNumber.from("100").mul(N1__0_18DEC);
        await _iporOracle.addUpdater(await userOne.getAddress());

        //when
        await _iporOracle.connect(userOne).updateIndex(asset, expectedIndexValue);

        //then
        const iporIndex = await _iporOracle.getIndex(asset);
        const actualIndexValue = BigNumber.from(iporIndex.indexValue);
        const actualIbtPrice = BigNumber.from(iporIndex.ibtPrice);

        expect(
            expectedIndexValue,
            `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValue}`
        ).to.be.eql(actualIndexValue);
        expect(
            TC_IBT_PRICE_DAI_18DEC,
            `Incorrect Interest Bearing Token Price ${actualIbtPrice}, expected ${TC_IBT_PRICE_DAI_18DEC.toString()}`
        ).to.be.eql(actualIbtPrice);
    });

    it("should add IPOR Index Updater", async () => {
        //given
        await _iporOracle.addUpdater(await userOne.getAddress());
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        const expectedIporIndexValue = BigNumber.from("7").mul(N0__01_18DEC);
        const assets = [_tokenUsdc.address, _tokenDai.address, _tokenUsdt.address];
        const indexValues = [
            BigNumber.from("7").mul(N0__01_18DEC),
            BigNumber.from("7").mul(N0__01_18DEC),
            BigNumber.from("7").mul(N0__01_18DEC),
        ];

        //when
        await _iporOracle.connect(userOne).itfUpdateIndexes(assets, indexValues, updateDate);

        //then
        const iporIndex = await _iporOracle.connect(userOne).getIndex(_tokenDai.address);
        const actualIndexValue = BigNumber.from(iporIndex.indexValue);

        expect(actualIndexValue).to.be.eql(expectedIporIndexValue);
    });

    it("should NOT add IPOR Index Updater", async () => {
        await assertError(
            _iporOracle.connect(userThree).addUpdater(await userTwo.getAddress()),
            "Ownable: caller is not the owner"
        );
    });

    it("should remove IPOR Index Updater", async () => {
        await _iporOracle.addUpdater(await userOne.getAddress());
        await _iporOracle.removeUpdater(await userOne.getAddress());

        await assertError(
            //when
            _iporOracle.connect(userOne).updateIndex(_tokenUsdt.address, 123),
            //then
            "IPOR_202"
        );
    });

    it("should NOT remove IPOR Index Updater", async () => {
        await assertError(
            _iporOracle.connect(userThree).removeUpdater(await userTwo.getAddress()),
            "Ownable: caller is not the owner"
        );
    });

    it("should update existing IPOR Index", async () => {
        //given
        const asset = _tokenUsdt.address;
        const expectedIndexValueOne = BigNumber.from("123000000000000000");
        const expectedIndexValueTwo = BigNumber.from("321000000000000000");
        await _iporOracle.addUpdater(await userOne.getAddress());

        //when
        await _iporOracle.connect(userOne).updateIndex(asset, expectedIndexValueOne);
        await _iporOracle.connect(userOne).updateIndex(asset, expectedIndexValueTwo);

        //then
        const iporIndex = await _iporOracle.getIndex(asset);
        const actualIndexValue = BigNumber.from(iporIndex.indexValue);

        expect(
            actualIndexValue,
            `Incorrect IPOR index value ${actualIndexValue}, expected ${expectedIndexValueOne}`
        ).to.be.eql(expectedIndexValueTwo);
    });

    it("should calculate initial Interest Bearing Token Price", async () => {
        //given
        const asset = _tokenUsdt.address;
        await _iporOracle.addUpdater(await userOne.getAddress());
        const iporIndexValue = BigNumber.from("50000").mul(N0__01_18DEC);

        //when
        await _iporOracle.connect(userOne).updateIndex(asset, iporIndexValue);

        //then
        const iporIndex = await _iporOracle.getIndex(asset);
        const actualIbtPrice = BigNumber.from(iporIndex.ibtPrice);
        const actualIndexValue = BigNumber.from(iporIndex.indexValue);

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
        const asset = _tokenUsdt.address;
        await _iporOracle.addUpdater(await userOne.getAddress());
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);
        const updateDateSecond = updateDate.add(YEAR_IN_SECONDS);

        const iporIndexSecondValue = BigNumber.from("51000000000000000");

        //when
        await _iporOracle
            .connect(userOne)
            .itfUpdateIndex(asset, iporIndexSecondValue, updateDateSecond);

        //then
        const iporIndex = await _iporOracle.getIndex(asset);
        const actualIbtPrice = BigNumber.from(iporIndex.ibtPrice);
        const actualIndexValue = BigNumber.from(iporIndex.indexValue);
        const expectedIbtPrice = BigNumber.from("105").mul(N0__01_18DEC);

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
        const asset = _tokenUsdt.address;
        let updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);
        updateDate = updateDate.add(MONTH_IN_SECONDS);
        const iporIndexSecondValue = PERCENTAGE_6_6DEC;

        //when
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, iporIndexSecondValue, updateDate);

        //then
        const iporIndex = await _iporOracle.getIndex(asset);
        const actualIbtPrice = BigNumber.from(iporIndex.ibtPrice);
        const actualIndexValue = BigNumber.from(iporIndex.indexValue);

        const expectedIbtPrice = BigNumber.from("1004109589041095890");

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
        const asset = _tokenUsdt.address;
        let updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());

        await _iporOracle.connect(userOne).itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);

        const actualFirstIporIndex = await _iporOracle.getIndex(asset);
        const actualFirstIbtPrice = BigNumber.from(actualFirstIporIndex.ibtPrice);
        const actualFirstIndexValue = BigNumber.from(actualFirstIporIndex.indexValue);

        updateDate = updateDate.add(BigNumber.from(1));

        const iporIndexSecondValue = PERCENTAGE_5_18DEC;

        //when
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, iporIndexSecondValue, updateDate);

        //then
        const actualSecondIporIndex = await _iporOracle.getIndex(asset);
        const actualSecondIbtPrice = BigNumber.from(actualSecondIporIndex.ibtPrice);
        const actualSecondIndexValue = BigNumber.from(actualSecondIporIndex.indexValue);

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
        const asset = _tokenDai.address;
        let updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);

        const actualFirstIporIndex = await _iporOracle.getIndex(asset);
        const actualFirstIbtPrice = BigNumber.from(actualFirstIporIndex.ibtPrice);
        const actualFirstIndexValue = BigNumber.from(actualFirstIporIndex.indexValue);

        updateDate = updateDate.add(BigNumber.from(1));

        const iporIndexSecondValue = PERCENTAGE_5_18DEC;

        //when
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, iporIndexSecondValue, updateDate);

        //then
        const actualSecondIporIndex = await _iporOracle.getIndex(asset);
        const actualSecondIbtPrice = BigNumber.from(actualSecondIporIndex.ibtPrice);
        const actualSecondIndexValue = BigNumber.from(actualSecondIporIndex.indexValue);

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
        const asset = _tokenUsdt.address;
        await _iporOracle.addUpdater(await userOne.getAddress());
        let updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, PERCENTAGE_5_18DEC, updateDate);
        updateDate = updateDate.add(YEAR_IN_SECONDS.div(BigNumber.from(2)));
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, PERCENTAGE_6_18DEC, updateDate);
        updateDate = updateDate.add(YEAR_IN_SECONDS.div(BigNumber.from(4)));

        let iporIndexThirdValue = PERCENTAGE_7_18DEC;

        //when
        await _iporOracle.connect(userOne).itfUpdateIndex(asset, iporIndexThirdValue, updateDate);

        //then
        const iporIndex = await _iporOracle.getIndex(asset);

        const actualIbtPrice = BigNumber.from(iporIndex.ibtPrice);
        const actualIndexValue = BigNumber.from(iporIndex.indexValue);
        const expectedIbtPrice = BigNumber.from("104").mul(N0__01_18DEC);

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
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());

        const assets = [await userOne.getAddress()];
        const indexValues = [BigNumber.from("5").mul(N0__01_18DEC)];

        await assertError(
            //when
            _iporOracle.connect(userOne).itfUpdateIndexes(assets, indexValues, updateDate),
            //then
            "IPOR_200"
        );
    });

    it("should NOT update IPOR Index - wrong input arrays", async () => {
        //given
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());

        const assets = [_tokenUsdc.address, _tokenDai.address];
        const indexValues = [BigNumber.from("5").mul(N0__01_18DEC)];

        await assertError(
            //when
            _iporOracle.connect(userOne).itfUpdateIndexes(assets, indexValues, updateDate),
            //then
            "IPOR_005"
        );
    });

    it("should NOT update IPOR Index - Accrue timestamp lower than current ipor index timestamp", async () => {
        //given
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());
        const assets = [_tokenUsdc.address, _tokenDai.address];
        const indexValues = [
            BigNumber.from("5").mul(N0__01_18DEC),
            BigNumber.from("5").mul(N0__01_18DEC),
        ];
        await _iporOracle.connect(userOne).itfUpdateIndexes(assets, indexValues, updateDate);

        const wrongUpdateDate = updateDate.sub(BigNumber.from(1));

        //when
        await assertError(
            //when
            _iporOracle.connect(userOne).itfUpdateIndexes(assets, indexValues, wrongUpdateDate),
            //then
            "IPOR_203"
        );
    });

    it("should update IPOR Index - correct input arrays", async () => {
        //given
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());

        const assets = [_tokenUsdc.address, _tokenDai.address, _tokenUsdt.address];
        const indexValues = [PERCENTAGE_8_18DEC, PERCENTAGE_7_18DEC, PERCENTAGE_5_18DEC];

        //when
        await _iporOracle.connect(userOne).itfUpdateIndexes(assets, indexValues, updateDate);

        //then
        for (let i = 0; i < assets.length; i++) {
            const iporIndex = await _iporOracle.getIndex(assets[i]);
            const actualIndexValue = BigNumber.from(iporIndex.indexValue);
            expect(
                actualIndexValue,
                `Actual IPOR Index Value is incorrect ${actualIndexValue}, expected ${indexValues[i]}`
            ).to.be.eql(indexValues[i]);
        }
    });

    it("should calculate initial Exponential Moving Average - simple case 1", async () => {
        //given
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());
        const assets = [_tokenDai.address, _tokenUsdc.address, _tokenUsdt.address];
        const indexValues = [PERCENTAGE_7_18DEC, PERCENTAGE_7_18DEC, PERCENTAGE_7_18DEC];
        const expectedExpoMovingAverage = PERCENTAGE_7_18DEC;
        //when
        await _iporOracle.connect(userOne).itfUpdateIndexes(assets, indexValues, updateDate);

        //then
        const iporIndex = await _iporOracle.getIndex(assets[0]);
        const actualExponentialMovingAverage = BigNumber.from(
            await iporIndex.exponentialMovingAverage
        );
        expect(
            actualExponentialMovingAverage,
            `Actual exponential moving average is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`
        ).to.be.eql(expectedExpoMovingAverage);
    });

    it("should calculate initial Exponential Moving Average - 2x IPOR Index updates - 18 decimals", async () => {
        //given
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());
        const assets = [_tokenDai.address, _tokenUsdt.address, _tokenUsdc.address];
        const firstIndexValues = [PERCENTAGE_7_18DEC, PERCENTAGE_7_18DEC, PERCENTAGE_7_18DEC];
        const secondIndexValues = [PERCENTAGE_50_18DEC, PERCENTAGE_50_18DEC, PERCENTAGE_50_18DEC];
        const expectedExpoMovingAverage = BigNumber.from("285000000000000000");

        //when
        await _iporOracle.connect(userOne).itfUpdateIndexes(assets, firstIndexValues, updateDate);
        await _iporOracle.connect(userOne).itfUpdateIndexes(assets, secondIndexValues, updateDate);

        //then
        const iporIndex = await _iporOracle.getIndex(assets[0]);
        const actualExponentialMovingAverage = BigNumber.from(
            await iporIndex.exponentialMovingAverage
        );
        expect(
            actualExponentialMovingAverage,
            `Actual exponential moving average for asset ${assets[0]} is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`
        ).to.be.eql(expectedExpoMovingAverage);
    });

    it("should calculate initial Exponential Moving Average - 2x IPOR Index updates - 6 decimals", async () => {
        //given
        const updateDate = BigNumber.from(Math.floor(Date.now() / 1000));
        await _iporOracle.addUpdater(await userOne.getAddress());
        const assets = [_tokenUsdc.address, _tokenDai.address, _tokenUsdt.address];
        const firstIndexValues = [PERCENTAGE_7_6DEC, PERCENTAGE_7_6DEC, PERCENTAGE_7_6DEC];
        const secondIndexValues = [PERCENTAGE_50_6DEC, PERCENTAGE_50_6DEC, PERCENTAGE_50_6DEC];
        const expectedExpoMovingAverage = BigNumber.from("285000");

        //when
        await _iporOracle.connect(userOne).itfUpdateIndexes(assets, firstIndexValues, updateDate);
        await _iporOracle.connect(userOne).itfUpdateIndexes(assets, secondIndexValues, updateDate);

        //then
        const iporIndex = await _iporOracle.getIndex(assets[0]);
        const actualExponentialMovingAverage = iporIndex.exponentialMovingAverage;
        expect(
            actualExponentialMovingAverage,
            `Actual exponential moving average for asset ${assets[0]} is incorrect ${actualExponentialMovingAverage}, expected ${expectedExpoMovingAverage}`
        ).to.be.eql(expectedExpoMovingAverage);
    });

    it("should not sent ETH to _iporOracle", async () => {
        //given

        await assertError(
            //when
            admin.sendTransaction({
                to: _iporOracle.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });
});
