const testUtils = require("./TestUtils.js");
const truffleAssert = require("truffle-assertions");

contract("IpToken", (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let data = null;
    let testData;

    before(async () => {
        data = await testUtils.prepareData();
    });

    beforeEach(async () => {
        testData = await testUtils.prepareTestData(
            [userTwo, liquidityProvider],
            ["DAI"],
            data
        );
    });

    it("should NOT mint ipToken if not a Liquidity Pool", async () => {
        //when
        await testUtils.assertError(
            //when
            testData.ipTokenDai.mint(userOne, testUtils.USD_10_000_18DEC, {
                from: userTwo,
            }),
            //then
            "IPOR_46"
        );
    });

    it("should NOT burn ipToken if not a Liquidity Pool", async () => {
        //when
        await testUtils.assertError(
            //when
            testData.ipTokenDai.burn(
                userOne,
                userTwo,
                testUtils.USD_10_000_18DEC,
                { from: userTwo }
            ),
            //then
            "IPOR_46"
        );
    });

    it("should emit event", async () => {
        //given
        await data.iporConfiguration.setJoseph(admin);

        //when
        let tx = await testData.ipTokenDai.mint(
            userOne,
            testUtils.USD_10_000_18DEC,
            { from: admin }
        );

        //then
        truffleAssert.eventEmitted(tx, "Mint", (ev) => {
            return ev.user == userOne && ev.value == testUtils.USD_10_000_18DEC;
        });
        await data.iporConfiguration.setJoseph(data.joseph.address);
    });

    it("should contain 18 decimals", async () => {
        //given
        await data.iporConfiguration.setJoseph(admin);
        const expectedDecimals = BigInt("18");
        //when
        let actualDecimals = BigInt(
            await testData.ipTokenDai.decimals({ from: admin })
        );

        //then
        assert(
            expectedDecimals === actualDecimals,
            `Incorrect decimals actual: ${actualDecimals}, expected: ${expectedDecimals}`
        );

        await data.iporConfiguration.setJoseph(data.joseph.address);
    });

    it("should contain correct underlying token address", async () => {
        //given
        const expectedUnderlyingTokenAddress = testData.tokenDai.address;
        //when
        let actualUnderlyingTokenAddress =
            await testData.ipTokenDai.getUnderlyingAssetAddress({
                from: admin,
            });

        //then
        assert(
            expectedUnderlyingTokenAddress === actualUnderlyingTokenAddress,
            `Incorrect underlying token address actual: ${actualUnderlyingTokenAddress}, expected: ${expectedUnderlyingTokenAddress}`
        );
    });
});
