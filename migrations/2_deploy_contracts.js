const IporOracle = artifacts.require("IporOracle");
const IporAmmV1 = artifacts.require("IporAmmV1");
const SimpleToken = artifacts.require('SimpleToken');

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;
    await deployer.deploy(IporOracle);
    const iporOracle = await IporOracle.deployed();

    //10 000 000 000 000 USD
    let totalSupply6Decimals = '1000000000000000000000';
    //10 000 000 000 000 USD
    let totalSupply18Decimals = '10000000000000000000000000000000000';

    //10 000 000 USD
    let userSupply6Decimals = '10000000000000';

    //10 000 000 USD
    let userSupply18Decimals = '10000000000000000000000000';

    let usdt = null;
    let usdc = null;
    let dai = null;
    let tusd = null;

    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'test') {

        await deployer.deploy(SimpleToken, 'Mocked USDT', 'USDT', totalSupply6Decimals, 6);
        usdt = await SimpleToken.deployed();

        //10 000 000 000 000 USD
        await deployer.deploy(SimpleToken, 'Mocked USDC', 'USDC', totalSupply6Decimals, 6);
        usdc = await SimpleToken.deployed();

        //10 000 000 000 000 USD
        await deployer.deploy(SimpleToken, 'Mocked DAI', 'DAI', totalSupply18Decimals, 18);
        dai = await SimpleToken.deployed();

        //10 000 000 000 000 USD
        await deployer.deploy(SimpleToken, 'Mocked TUSD', 'TUSD', totalSupply18Decimals, 18);
        tusd = await SimpleToken.deployed();
    }

    const iporAmm = await deployer.deploy(IporAmmV1, iporOracle.address, usdt.address, usdc.address, dai.address);

    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'test') {

        //first address is an admin, last two addresses will not have tokens and approves
        for (let i = 1; i < addresses.length - 2; i++) {
            await usdt.transfer(addresses[i], userSupply6Decimals);
            await usdc.transfer(addresses[i], userSupply6Decimals);
            await dai.transfer(addresses[i], userSupply18Decimals);
            await tusd.transfer(addresses[i], userSupply18Decimals);

            //AMM has rights to spend money on behalf of user
            usdt.approve(iporAmm.address, totalSupply6Decimals, {from: addresses[i]});
            usdc.approve(iporAmm.address, totalSupply6Decimals, {from: addresses[i]});
            dai.approve(iporAmm.address, totalSupply18Decimals, {from: addresses[i]});
            tusd.approve(iporAmm.address, totalSupply18Decimals, {from: addresses[i]});
        }
    }

};