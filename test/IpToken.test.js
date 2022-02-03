const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
    assertError,
    prepareData,
    prepareTestData,
    getLibraries,
} = require("./Utils");

const { USD_10_000_18DEC } = require("./Const.js");

describe("IpToken", () => {
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
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            data,
            libraries
        );
    });

    it("should NOT mint ipToken if not a Liquidity Pool", async () => {
        //when
        await assertError(
            //when
            testData.ipTokenDai
                .connect(userTwo)
                .mint(userOne.address, USD_10_000_18DEC),
            //then
            "IPOR_46"
        );
    });

    it("should NOT burn ipToken if not a Liquidity Pool", async () => {
        //when
        await assertError(
            //when
            testData.ipTokenDai
                .connect(userTwo)
                .burn(userOne.address, userTwo.address, USD_10_000_18DEC),
            //then
            "IPOR_46"
        );
    });

    it("should emit event", async () => {
        //given
        await testData.ipTokenDai.setJoseph(admin.address);

        await expect(
            testData.ipTokenDai.mint(userOne.address, USD_10_000_18DEC)
        )
            .to.emit(testData.ipTokenDai, "Mint")
            .withArgs(userOne.address, USD_10_000_18DEC);

        await testData.ipTokenDai.setJoseph(
            testData.josephDai.address
        );
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

        await testData.ipTokenDai.setJoseph(
            testData.josephDai.address
        );
    });

    it("should contain correct underlying token address", async () => {
        //given
        const expectedUnderlyingTokenAddress = testData.tokenDai.address;
        //when
        let actualUnderlyingTokenAddress =
            await testData.ipTokenDai.getUnderlyingAssetAddress();

        //then
        expect(
            expectedUnderlyingTokenAddress,
            `Incorrect underlying token address actual: ${actualUnderlyingTokenAddress}, expected: ${expectedUnderlyingTokenAddress}`
        ).to.be.eql(actualUnderlyingTokenAddress);
    });
});
