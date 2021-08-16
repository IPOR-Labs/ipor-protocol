const Warren = artifacts.require("Warren");
const MiltonV1 = artifacts.require("MiltonV1");
const TestWarrenProxy = artifacts.require("TestWarrenProxy");
const TestMiltonV1Proxy = artifacts.require("TestMiltonV1Proxy");
const TusdMockedToken = artifacts.require('TusdMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const DaiMockedToken = artifacts.require('DaiMockedToken');
const IporLogic = artifacts.require('IporLogic');
const DerivativeLogic = artifacts.require('DerivativeLogic');
const SoapIndicatorLogic = artifacts.require('SoapIndicatorLogic');
const SpreadIndicatorLogic = artifacts.require('SpreadIndicatorLogic');
const TotalSoapIndicatorLogic = artifacts.require('TotalSoapIndicatorLogic');
const DerivativesView = artifacts.require('DerivativesView');
const MiltonConfiguration = artifacts.require('MiltonConfiguration');
const AmmMath = artifacts.require('AmmMath');

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;

    await deployer.deploy(AmmMath);
    await deployer.link(AmmMath, IporLogic);

    await deployer.deploy(IporLogic);
    await deployer.link(AmmMath, Warren);
    await deployer.link(IporLogic, Warren);
    await deployer.deploy(Warren);
    const warren = await Warren.deployed();

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
    let miltonConfiguration = null;

    await deployer.link(AmmMath, DerivativeLogic);
    await deployer.deploy(DerivativeLogic);
    await deployer.link(AmmMath, SoapIndicatorLogic);
    await deployer.deploy(SoapIndicatorLogic);
    await deployer.deploy(SpreadIndicatorLogic);
    await deployer.link(SoapIndicatorLogic, TotalSoapIndicatorLogic);
    await deployer.deploy(TotalSoapIndicatorLogic);
    await deployer.deploy(DerivativesView);
    await deployer.link(SoapIndicatorLogic, MiltonV1);
    await deployer.link(SpreadIndicatorLogic, MiltonV1);
    await deployer.link(DerivativeLogic, MiltonV1);
    await deployer.link(DerivativesView, MiltonV1);

    await deployer.link(TotalSoapIndicatorLogic, MiltonV1);

    await deployer.link(AmmMath, MiltonV1);

    await deployer.deploy(MiltonConfiguration);
    miltonConfiguration = await MiltonConfiguration.deployed();

    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {

        await deployer.deploy(UsdtMockedToken, totalSupply6Decimals, 6);
        usdt = await UsdtMockedToken.deployed();

        //10 000 000 000 000 USD
        await deployer.deploy(UsdcMockedToken, totalSupply6Decimals, 6);
        usdc = await UsdcMockedToken.deployed();

        //10 000 000 000 000 USD
        await deployer.deploy(DaiMockedToken, totalSupply18Decimals, 18);
        dai = await DaiMockedToken.deployed();

        //10 000 000 000 000 USD
        await deployer.deploy(TusdMockedToken, totalSupply18Decimals, 18);
        tusd = await TusdMockedToken.deployed();
    }

    if (_network == 'develop2' || _network === 'docker') {
        //by default add ADMIN as updater for IPOR Oracle
        await warren.addUpdater(admin);
        await warren.updateIndex("DAI", BigInt("30000000000000000"));
        await warren.updateIndex("USDT", BigInt("30000000000000000"));
        await warren.updateIndex("USDC", BigInt("30000000000000000"));
    }

    let milton = null;

    if (_network !== 'test') {
        milton = await deployer.deploy(MiltonV1, miltonConfiguration.address, warren.address, usdt.address, usdc.address, dai.address);
    } else {
        await deployer.link(AmmMath, TestWarrenProxy);
        await deployer.link(IporLogic, TestWarrenProxy);
        await deployer.link(DerivativeLogic, TestMiltonV1Proxy);
        await deployer.link(SoapIndicatorLogic, TestMiltonV1Proxy);
        await deployer.link(SpreadIndicatorLogic, TestMiltonV1Proxy);
        await deployer.link(TotalSoapIndicatorLogic, TestMiltonV1Proxy);
        await deployer.link(DerivativesView, TestMiltonV1Proxy);
        await deployer.link(AmmMath, TestMiltonV1Proxy);
    }

    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {
        console.log("Start transfer TOKENS to test addresses...");
        //first address is an admin, last two addresses will not have tokens and approves
        for (let i = 0; i < addresses.length - 2; i++) {
            await usdt.transfer(addresses[i], userSupply6Decimals);
            await usdc.transfer(addresses[i], userSupply6Decimals);
            await dai.transfer(addresses[i], userSupply18Decimals);
            await tusd.transfer(addresses[i], userSupply18Decimals);

            console.log(`Account: ${addresses[i]} - tokens transfered`);

            //AMM has rights to spend money on behalf of user
            //TODO: Use safeIncreaseAllowance() and safeDecreaseAllowance() from OpenZepppelin’s SafeERC20 implementation to prevent race conditions from manipulating the allowance amounts.
            usdt.approve(milton.address, totalSupply6Decimals, {from: addresses[i]});
            usdc.approve(milton.address, totalSupply6Decimals, {from: addresses[i]});
            dai.approve(milton.address, totalSupply18Decimals, {from: addresses[i]});
            tusd.approve(milton.address, totalSupply18Decimals, {from: addresses[i]});

            console.log(`Account: ${addresses[i]} approve spender ${milton.address} to spend tokens on behalf of user.`);
        }
    }

};