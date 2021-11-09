const testUtils = require("./TestUtils.js");

contract('IpToken', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let data = null;
    let testData

    before(async () => {
        data = await testUtils.prepareDataForBefore(accounts);
    });

    beforeEach(async () => {
        testData = await testUtils.prepareDataForBeforeEach(data);
    });


    it('should NOT mint ipToken if not a Liquidity Pool', async () => {

        //when
        await testUtils.assertError(
            //when
            testData.ipTokenDai.mint(userOne, testUtils.USD_10_000_18DEC, {from: userTwo}),
            //then
            'IPOR_46'
        );

    });

    it('should NOT burn ipToken if not a Liquidity Pool', async () => {
        //when
        await testUtils.assertError(
            //when
            testData.ipTokenDai.burn(userOne, userTwo, testUtils.USD_10_000_18DEC, {from: userTwo}),
            //then
            'IPOR_46'
        );
    });
});
