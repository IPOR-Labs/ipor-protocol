require('dotenv').config({path: '../.env'})

const Warren = artifacts.require("Warren");
const WarrenStorage = artifacts.require("WarrenStorage");
const Milton = artifacts.require("Milton");
const MiltonStorage = artifacts.require("MiltonStorage");
const MiltonFaucet = artifacts.require("MiltonFaucet");
const TestWarren = artifacts.require("TestWarren");
const TestMilton = artifacts.require("TestMilton");
const IporToken = artifacts.require('IporToken');
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
const IporAddressesManager = artifacts.require('IporAddressesManager');
const MiltonDevToolDataProvider = artifacts.require('MiltonDevToolDataProvider');
const WarrenDevToolDataProvider = artifacts.require('WarrenDevToolDataProvider');
const MiltonFrontendDataProvider = artifacts.require('MiltonFrontendDataProvider');
const MiltonLPUtilizationStrategyCollateral = artifacts.require('MiltonLPUtilizationStrategyCollateral');


module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;

    await deployer.deploy(AmmMath);
    await deployer.link(AmmMath, IporLogic);

    await deployer.deploy(IporLogic);
    await deployer.link(AmmMath, Warren);
    await deployer.link(IporLogic, Warren);

    let isTestEnvironment = 1;
    if (_network === "mainnet") {
        isTestEnvironment = 0;
    }

    await deployer.link(IporLogic, WarrenStorage);
    await deployer.deploy(WarrenStorage);
    let warrenStorage = await WarrenStorage.deployed();
    let warrenStorageAddr = warrenStorage.address;

    await deployer.deploy(Warren, warrenStorageAddr);
    const warren = await Warren.deployed();

    let faucetSupply6Decimals = '1000000000000000000000000';
    let totalSupply6Decimals = '1000000000000000000000000000';

    let faucetSupply18Decimals = '10000000000000000000000000000000000000';
    let totalSupply18Decimals = '10000000000000000000000000000000000000000';

    let userSupply6Decimals = '10000000000000';
    let userSupply18Decimals = '10000000000000000000000000';

    let ipUsdtToken = null;
    let ipUsdcToken = null;
    let ipDaiToken = null;

    let mockedUsdt = null;
    let mockedUsdtAddr = null;
    let mockedUsdc = null;
    let mockedUsdcAddr = null;
    let mockedDai = null;
    let mockedDaiAddr = null;
    let mockedTusd = null;
    let mockedTusdAddr = null;
    let warrenAddr = null;
    let milton = null;
    let testMilton = null;
    let miltonAddr = null;
    let miltonStorage = null;
    let miltonStorageAddr = null;
    let miltonFaucet = null;
    let miltonFaucetAddr = null;
    let miltonConfiguration = null;
    let iporAddressesManager = null;

    await deployer.link(AmmMath, DerivativeLogic);
    await deployer.deploy(DerivativeLogic);

    await deployer.link(AmmMath, SoapIndicatorLogic);
    await deployer.deploy(SoapIndicatorLogic);
    await deployer.deploy(SpreadIndicatorLogic);

    await deployer.link(SoapIndicatorLogic, TotalSoapIndicatorLogic);
    await deployer.deploy(TotalSoapIndicatorLogic);

    await deployer.deploy(DerivativesView);

    await deployer.link(SoapIndicatorLogic, MiltonStorage);
    await deployer.link(SpreadIndicatorLogic, MiltonStorage);
    await deployer.link(DerivativeLogic, MiltonStorage);
    await deployer.link(TotalSoapIndicatorLogic, MiltonStorage);
    await deployer.link(DerivativesView, MiltonStorage);
    await deployer.link(DerivativeLogic, Milton);
    await deployer.link(AmmMath, MiltonStorage);

    await deployer.deploy(MiltonConfiguration);
    miltonConfiguration = await MiltonConfiguration.deployed();

    await deployer.deploy(IporAddressesManager);
    iporAddressesManager = await IporAddressesManager.deployed();
    let iporAddressesManagerAddr = await iporAddressesManager.address;

    await deployer.deploy(MiltonFrontendDataProvider, iporAddressesManagerAddr);

    await deployer.link(AmmMath, MiltonLPUtilizationStrategyCollateral);
    await deployer.deploy(MiltonLPUtilizationStrategyCollateral);
    let miltonLPUtilizationStrategyCollateral = await MiltonLPUtilizationStrategyCollateral.deployed();
    await iporAddressesManager.setAddress("MILTON_UTILIZATION_STRATEGY", miltonLPUtilizationStrategyCollateral.address);

    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {

        await deployer.deploy(UsdtMockedToken, totalSupply6Decimals, 6);
        mockedUsdt = await UsdtMockedToken.deployed();
        mockedUsdtAddr = await mockedUsdt.address;

        await deployer.deploy(UsdcMockedToken, totalSupply6Decimals, 6);
        mockedUsdc = await UsdcMockedToken.deployed();
        mockedUsdcAddr = await mockedUsdc.address;

        await deployer.deploy(DaiMockedToken, totalSupply18Decimals, 18);
        mockedDai = await DaiMockedToken.deployed();
        mockedDaiAddr = await mockedDai.address;

        await deployer.deploy(TusdMockedToken, totalSupply18Decimals, 18);
        mockedTusd = await TusdMockedToken.deployed();
        mockedTusdAddr = await mockedTusd.address;

        await deployer.deploy(MiltonFaucet,
            mockedUsdtAddr,
            mockedUsdcAddr,
            mockedDaiAddr,
            mockedTusdAddr);

        miltonFaucet = await MiltonFaucet.deployed();
        miltonFaucetAddr = await miltonFaucet.address;
        miltonFaucet.sendTransaction({from: admin, value: "500000000000000000000000"});

        await deployer.deploy(MiltonDevToolDataProvider, iporAddressesManagerAddr);

        await deployer.link(AmmMath, WarrenDevToolDataProvider);
        await deployer.deploy(WarrenDevToolDataProvider, iporAddressesManagerAddr);

        await deployer.deploy(IporToken, mockedUsdtAddr, 6, "IPOR USDT", "ipUSDT");
        ipUsdtToken = await IporToken.deployed();
        await iporAddressesManager.setIporToken(mockedUsdtAddr, ipUsdtToken.address);
        await deployer.deploy(IporToken, mockedUsdcAddr, 6, "IPOR USDC", "ipUSDC");
        ipUsdcToken = await IporToken.deployed();
        await iporAddressesManager.setIporToken(mockedUsdcAddr, ipUsdcToken.address);
        await deployer.deploy(IporToken, mockedDaiAddr, 18, "IPOR DAI", "ipDAI");
        ipDaiToken = await IporToken.deployed();
        await iporAddressesManager.setIporToken(mockedDaiAddr, ipDaiToken.address);

    } else {
        if (_network !== 'test') {
            await deployer.deploy(IporToken, process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS, 6, "IPOR USDT", "ipUSDT");
            ipUsdtToken = await IporToken.deployed();
            await iporAddressesManager.setIporToken(process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS, ipUsdtToken.address);
            await deployer.deploy(IporToken, process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS, 6, "IPOR USDC", "ipUSDC");
            ipUsdcToken = await IporToken.deployed();
            await iporAddressesManager.setIporToken(process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS, ipUsdcToken.address);
            await deployer.deploy(IporToken, process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS, 18, "IPOR DAI", "ipDAI");
            ipDaiToken = await IporToken.deployed();
            await iporAddressesManager.setIporToken(process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS, ipDaiToken.address);
        }


    }

    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {
        console.log("Setup Warren...")
        //by default add ADMIN as updater for IPOR Oracle
        await warrenStorage.addUpdater(admin);
        await warrenStorage.addUpdater(warren.address);

        if (process.env.INITIAL_IPOR_MIGRATION_ENABLED === "true") {
            console.log("Prepare initial IPOR migration...")
            await warren.updateIndexes(
                [mockedDaiAddr, mockedUsdtAddr, mockedUsdcAddr],
                [BigInt("30000000000000000"), BigInt("30000000000000000"), BigInt("30000000000000000")]);
        }
    }

    if (_network !== 'test') {
        await deployer.link(AmmMath, Milton);
        await deployer.deploy(Milton);
        milton = await Milton.deployed();

        await deployer.deploy(MiltonStorage);
        miltonStorage = await MiltonStorage.deployed();

        warrenAddr = await warren.address;
        miltonAddr = await milton.address;
        miltonStorageAddr = await miltonStorage.address;
        const miltonConfigurationAddr = await miltonConfiguration.address;

        //initial addresses setup
        await iporAddressesManager.setAddress("WARREN", warrenAddr);
        await iporAddressesManager.setAddress("WARREN_STORAGE", warrenStorageAddr);
        await iporAddressesManager.setAddress("MILTON_STORAGE", miltonStorageAddr);
        await iporAddressesManager.setAddress("MILTON_CONFIGURATION", miltonConfigurationAddr);

        //TestWarren
        await deployer.link(AmmMath, TestWarren);
        await deployer.link(IporLogic, TestWarren);
        await deployer.deploy(TestWarren, warrenStorageAddr);
        let testWarren = await TestWarren.deployed();
        await warrenStorage.addUpdater(testWarren.address);

        //TestMilton
        await deployer.link(AmmMath, TestMilton);
        await deployer.link(DerivativeLogic, TestMilton);
        await deployer.deploy(TestMilton);
        testMilton = await TestMilton.deployed();

        if (_network === 'develop' || _network === 'dev' || _network === 'docker') {
            if (process.env.PRIV_TEST_NETWORK_USE_TEST_MILTON === "true") {
                await iporAddressesManager.setAddress("MILTON", testMilton.address);
            } else {
                await iporAddressesManager.setAddress("MILTON", miltonAddr);
            }
        } else {
            await iporAddressesManager.setAddress("MILTON", miltonAddr);
        }

        await testMilton.initialize(iporAddressesManagerAddr);

        await milton.initialize(iporAddressesManagerAddr);
        await miltonStorage.initialize(iporAddressesManagerAddr);

    } else {
        await deployer.link(AmmMath, TestWarren);
        await deployer.link(IporLogic, TestWarren);
        await deployer.link(DerivativeLogic, TestMilton);
        await deployer.link(AmmMath, TestMilton);
        await deployer.deploy(MiltonDevToolDataProvider, iporAddressesManagerAddr);
        await deployer.link(AmmMath, WarrenDevToolDataProvider);
        await deployer.deploy(WarrenDevToolDataProvider, iporAddressesManagerAddr);

    }

    await miltonLPUtilizationStrategyCollateral.initialize(iporAddressesManagerAddr);

    //Prepare tokens for initial accounts...
    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {
        console.log("Setup Faucet...");
        await mockedUsdt.transfer(miltonFaucetAddr, faucetSupply6Decimals);
        await mockedUsdc.transfer(miltonFaucetAddr, faucetSupply6Decimals);
        await mockedDai.transfer(miltonFaucetAddr, faucetSupply18Decimals);
        await mockedTusd.transfer(miltonFaucetAddr, faucetSupply18Decimals);
        console.log("Setup Faucet finished.");

        console.log("Start transfer TOKENS to test addresses...");
        //first address is an admin, last two addresses will not have tokens and approves
        for (let i = 0; i < addresses.length - 2; i++) {
            await mockedUsdt.transfer(addresses[i], userSupply6Decimals);
            await mockedUsdc.transfer(addresses[i], userSupply6Decimals);
            await mockedDai.transfer(addresses[i], userSupply18Decimals);
            await mockedTusd.transfer(addresses[i], userSupply18Decimals);

            console.log(`Account: ${addresses[i]} - tokens transferred`);

            //AMM has rights to spend money on behalf of user
            //TODO: Use safeIncreaseAllowance() and safeDecreaseAllowance() from OpenZepppelin’s SafeERC20 implementation to prevent race conditions from manipulating the allowance amounts.
            mockedUsdt.approve(miltonAddr, totalSupply6Decimals, {from: addresses[i]});
            mockedUsdc.approve(miltonAddr, totalSupply6Decimals, {from: addresses[i]});
            mockedDai.approve(miltonAddr, totalSupply18Decimals, {from: addresses[i]});
            mockedTusd.approve(miltonAddr, totalSupply18Decimals, {from: addresses[i]});

            if (isTestEnvironment) {
                mockedUsdt.approve(testMilton.address, totalSupply6Decimals, {from: addresses[i]});
                mockedUsdc.approve(testMilton.address, totalSupply6Decimals, {from: addresses[i]});
                mockedDai.approve(testMilton.address, totalSupply18Decimals, {from: addresses[i]});
                mockedTusd.approve(testMilton.address, totalSupply18Decimals, {from: addresses[i]});
            }

            console.log(`Account: ${addresses[i]} approve spender ${miltonAddr} to spend tokens on behalf of user.`);
        }
    }

};