const testUtils = require("./TestUtils.js");

contract('IporToken', (accounts) => {

    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let data = null;
    let testData

    before(async () => {
        data = await testUtils.prepareDataForBefore(accounts);
    });

    beforeEach(async () => {
        testData = await testUtils.prepareDataForBeforeEach(data);
    });


    it('should NOT mint IPOR Token if not a Liquidity Pool', async () => {

        //when
        await testUtils.assertError(
            //when
            testData.iporTokenDai.mint(userOne, testUtils.USD_10_000_18DEC, {from: userTwo}),
            //then
            'IPOR_46'
        );

    });

    it('should NOT burn IPOR Token if not a Liquidity Pool', async () => {
        //when
        await testUtils.assertError(
            //when
            testData.iporTokenDai.burn(userOne, userTwo, testUtils.USD_10_000_18DEC, {from: userTwo}),
            //then
            'IPOR_46'
        );
    });
});
