const IporAmm = artifacts.require('IporAmm');
const IporOracle = artifacts.require('IporOracle');

contract('IporAmm', (accounts) => {

    const [admin, updaterOne, updaterTwo, user] = accounts;

    let amm = null;
    let iporOracle = null;

    before(async () => {
        iporOracle = await IporOracle.deployed();
        amm = await IporAmm.deployed();
        await iporOracle.addUpdater(updaterOne);
    });

    it('should read Index from IPOR Oracle Smart Contract', async () => {
        let ticker = "USDT";
        let expectedValue = 111;
        await iporOracle.updateIndex(ticker, expectedValue, {from: updaterOne});
        const iporIndexAmm = await amm.readIndex(ticker);
        let actualValue = parseInt(iporIndexAmm.value);
        assert(expectedValue === actualValue);
    });
});