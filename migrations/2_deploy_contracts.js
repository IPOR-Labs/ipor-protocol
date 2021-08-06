const IporOracle = artifacts.require("IporOracle");
const IporAmmV1 = artifacts.require("IporAmmV1");
const TestIporOracleProxy = artifacts.require("TestIporOracleProxy");
const TestIporAmmV1Proxy = artifacts.require("TestIporAmmV1Proxy");
const SimpleToken = artifacts.require('SimpleToken');
const IporLogic = artifacts.require('IporLogic');
const DerivativeLogic = artifacts.require('DerivativeLogic');
const SoapIndicatorLogic = artifacts.require('SoapIndicatorLogic');
const SpreadIndicatorLogic = artifacts.require('SpreadIndicatorLogic');
const TotalSoapIndicatorLogic = artifacts.require('TotalSoapIndicatorLogic');
const DerivativesView = artifacts.require('DerivativesView');

const AmmMath = artifacts.require('AmmMath');

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;

    await deployer.deploy(IporLogic);
    await deployer.link(IporLogic, IporOracle);
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

    await deployer.deploy(DerivativeLogic);
    await deployer.deploy(SoapIndicatorLogic);
    await deployer.deploy(SpreadIndicatorLogic);
    await deployer.link(SoapIndicatorLogic, TotalSoapIndicatorLogic);
    await deployer.deploy(TotalSoapIndicatorLogic);
    await deployer.deploy(DerivativesView);
    await deployer.link(SoapIndicatorLogic, IporAmmV1);
    await deployer.link(SpreadIndicatorLogic, IporAmmV1);
    await deployer.link(DerivativeLogic, IporAmmV1);
    await deployer.link(DerivativesView, IporAmmV1);

    await deployer.link(TotalSoapIndicatorLogic, IporAmmV1);
    await deployer.deploy(AmmMath);
    await deployer.link(AmmMath, IporAmmV1);

    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {

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

    if (_network == 'develop2' || _network === 'docker') {
        //by default add ADMIN as updater for IPOR Oracle
        await iporOracle.addUpdater(admin);
        await iporOracle.updateIndex("DAI", BigInt("30000000000000000"));
        await iporOracle.updateIndex("USDT", BigInt("30000000000000000"));
        await iporOracle.updateIndex("USDC", BigInt("30000000000000000"));
    }

    let iporAmm = null;

    if (_network !== 'test') {
        iporAmm = await deployer.deploy(IporAmmV1, iporOracle.address, usdt.address, usdc.address, dai.address);
    } else {
        await deployer.link(IporLogic, TestIporOracleProxy);
        await deployer.link(DerivativeLogic, TestIporAmmV1Proxy);
        await deployer.link(SoapIndicatorLogic, TestIporAmmV1Proxy);
        await deployer.link(SpreadIndicatorLogic, TestIporAmmV1Proxy);
        await deployer.link(TotalSoapIndicatorLogic, TestIporAmmV1Proxy);
        await deployer.link(DerivativesView, TestIporAmmV1Proxy);
        await deployer.link(AmmMath, TestIporAmmV1Proxy);
    }

    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {

        //first address is an admin, last two addresses will not have tokens and approves
        for (let i = 1; i < addresses.length - 2; i++) {
            await usdt.transfer(addresses[i], userSupply6Decimals);
            await usdc.transfer(addresses[i], userSupply6Decimals);
            await dai.transfer(addresses[i], userSupply18Decimals);
            await tusd.transfer(addresses[i], userSupply18Decimals);

            //AMM has rights to spend money on behalf of user
            //TODO: Use safeIncreaseAllowance() and safeDecreaseAllowance() from OpenZepppelin’s SafeERC20 implementation to prevent race conditions from manipulating the allowance amounts.
            usdt.approve(iporAmm.address, totalSupply6Decimals, {from: addresses[i]});
            usdc.approve(iporAmm.address, totalSupply6Decimals, {from: addresses[i]});
            dai.approve(iporAmm.address, totalSupply18Decimals, {from: addresses[i]});
            tusd.approve(iporAmm.address, totalSupply18Decimals, {from: addresses[i]});
        }
    }

};