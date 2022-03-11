const { expect } = require("chai");
const { ethers } = require("hardhat");

const { assertError, prepareData, prepareTestData, prepareTestDataDaiCase1 } = require("./Utils");

const { TC_TOTAL_AMOUNT_10_000_18DEC } = require("./Const.js");

describe("IpToken", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let data = null;
    let testData;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        data = await prepareData([admin, userOne, userTwo, userThree, liquidityProvider], 1);
    });

    beforeEach(async () => {
        testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            0,
            1
        );
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.ipTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.ipTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await testData.ipTokenDai.connect(userOne).owner();
        expect(expectedNewOwner.address).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            testData.ipTokenDai.connect(userThree).transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.ipTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await assertError(
            testData.ipTokenDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const testData = await prepareTestDataDaiCase1(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            data
        );
        const expectedNewOwner = userTwo;

        //when
        await testData.ipTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.ipTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            testData.ipTokenDai.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1,
            1
        );
        const expectedNewOwner = userTwo;

        await testData.ipTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await testData.ipTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            testData.ipTokenDai.connect(admin).transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            1,
            1
        );
        const expectedNewOwner = userTwo;

        await testData.ipTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        //when
        await testData.ipTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        //then
        const actualNewOwner = await testData.ipTokenDai.connect(userOne).owner();
        expect(admin.address).to.be.eql(actualNewOwner);
    });

    it("should NOT mint ipToken if not a Joseph", async () => {
        //when
        await assertError(
            //when
            testData.ipTokenDai
                .connect(userTwo)
                .mint(userOne.address, TC_TOTAL_AMOUNT_10_000_18DEC),
            //then
            "IPOR_325"
        );
    });

    it("should NOT burn ipToken if not a Joseph", async () => {
        //when
        await assertError(
            //when
            testData.ipTokenDai
                .connect(userTwo)
                .burn(userOne.address, TC_TOTAL_AMOUNT_10_000_18DEC),
            //then
            "IPOR_325"
        );
    });

    it("should emit event", async () => {
        //given
        await testData.ipTokenDai.setJoseph(admin.address);

        await expect(testData.ipTokenDai.mint(userOne.address, TC_TOTAL_AMOUNT_10_000_18DEC))
            .to.emit(testData.ipTokenDai, "Mint")
            .withArgs(userOne.address, TC_TOTAL_AMOUNT_10_000_18DEC);

        await testData.ipTokenDai.setJoseph(testData.josephDai.address);
    });

    it("should contain 18 decimals", async () => {
        //given
        await testData.ipTokenDai.setJoseph(admin.address);
        const expectedDecimals = BigInt("18");
        //when
        let actualDecimals = BigInt(await testData.ipTokenDai.decimals());

        //then
        expect(
            expectedDecimals,
            `Incorrect decimals actual: ${actualDecimals}, expected: ${expectedDecimals}`
        ).to.be.eql(actualDecimals);

        await testData.ipTokenDai.setJoseph(testData.josephDai.address);
    });

    it("should contain correct underlying token address", async () => {
        //given
        const expectedUnderlyingTokenAddress = testData.tokenDai.address;
        //when
        let actualUnderlyingTokenAddress = await testData.ipTokenDai.getAsset();

        //then
        expect(
            expectedUnderlyingTokenAddress,
            `Incorrect underlying token address actual: ${actualUnderlyingTokenAddress}, expected: ${expectedUnderlyingTokenAddress}`
        ).to.be.eql(actualUnderlyingTokenAddress);
    });
});
