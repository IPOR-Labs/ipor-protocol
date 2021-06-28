const IporAmmV1 = artifacts.require('IporAmmV1');
const IporOracle = artifacts.require('IporOracle');

contract('IporAmm', (accounts) => {

    const [admin, updaterOne, updaterTwo, user, usdtToken, usdcToken, daiToken] = accounts;

    let amm = null;
    let iporOracle = null;

    before(async () => {
        iporOracle = await IporOracle.deployed();
        amm = await IporAmmV1.deployed();
        await iporOracle.addUpdater(updaterOne);
    });

    it('should read Index from IPOR Oracle Smart Contract', async () => {
        //given
        let ticker = "USDT";
        let expectedValue = 111;
        let expectedInterestBearingToken = 234;
        await iporOracle.updateIndex(ticker, expectedValue, expectedInterestBearingToken, {from: updaterOne});

        //when
        const iporIndexAmm = await amm.readIndex(ticker);

        //then
        let actualValue = parseInt(iporIndexAmm.value);
        assert(expectedValue === actualValue);
    });
});