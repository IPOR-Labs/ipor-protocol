require('dotenv').config({path: '../.env'})
const keccak256 = require('keccak256')
const Warren = artifacts.require("Warren");
const WarrenStorage = artifacts.require("WarrenStorage");
const Milton = artifacts.require("Milton");
const MiltonStorage = artifacts.require("MiltonStorage");
const MiltonFaucet = artifacts.require("MiltonFaucet");
const TestWarren = artifacts.require("TestWarren");
const TestMilton = artifacts.require("TestMilton");
const TestJoseph = artifacts.require("TestJoseph");
const IpToken = artifacts.require('IpToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const DaiMockedToken = artifacts.require('DaiMockedToken');
const IporLogic = artifacts.require('IporLogic');
const DerivativeLogic = artifacts.require('DerivativeLogic');
const SoapIndicatorLogic = artifacts.require('SoapIndicatorLogic');
const SpreadIndicatorLogic = artifacts.require('SpreadIndicatorLogic');
const TotalSoapIndicatorLogic = artifacts.require('TotalSoapIndicatorLogic');
const DerivativesView = artifacts.require('DerivativesView');
const IporConfiguration = artifacts.require('IporConfiguration');
const AmmMath = artifacts.require('AmmMath');
const IporAddressesManager = artifacts.require('IporAddressesManager');
const MiltonDevToolDataProvider = artifacts.require('MiltonDevToolDataProvider');
const WarrenDevToolDataProvider = artifacts.require('WarrenDevToolDataProvider');
const WarrenFrontendDataProvider = artifacts.require('WarrenFrontendDataProvider');
const MiltonFrontendDataProvider = artifacts.require('MiltonFrontendDataProvider');
const MiltonLPUtilizationStrategyCollateral = artifacts.require('MiltonLPUtilizationStrategyCollateral');
const MiltonSpreadStrategy = artifacts.require('MiltonSpreadStrategy');
const Joseph = artifacts.require('Joseph');


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
    let warrenAddr = null;
    let milton = null;
    let testMilton = null;
    let testJoseph = null;
    let miltonAddr = null;
    let miltonStorage = null;
    let miltonStorageAddr = null;
    let miltonFaucet = null;
    let miltonFaucetAddr = null;
    let iporConfigurationUsdt = null;
    let iporConfigurationUsdc = null;
    let iporConfigurationDai = null;
    let iporAddressesManager = null;
    let joseph = null;

    await deployer.link(AmmMath, IporConfiguration);
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

    await deployer.deploy(IporAddressesManager);
    iporAddressesManager = await IporAddressesManager.deployed();
    let iporAddressesManagerAddr = await iporAddressesManager.address;

    await deployer.deploy(MiltonFrontendDataProvider, iporAddressesManagerAddr);

    await deployer.link(AmmMath, WarrenFrontendDataProvider);
    await deployer.deploy(WarrenFrontendDataProvider, iporAddressesManagerAddr);

    await deployer.link(AmmMath, MiltonLPUtilizationStrategyCollateral);
    await deployer.deploy(MiltonLPUtilizationStrategyCollateral);
    let miltonLPUtilizationStrategyCollateral = await MiltonLPUtilizationStrategyCollateral.deployed();
    await iporAddressesManager.setAddress(keccak256("MILTON_UTILIZATION_STRATEGY"), miltonLPUtilizationStrategyCollateral.address);

    await deployer.deploy(MiltonSpreadStrategy);
    let miltonSpreadStrategy = await MiltonSpreadStrategy.deployed();
    await iporAddressesManager.setAddress(keccak256("MILTON_SPREAD_STRATEGY"), miltonSpreadStrategy.address);

    // prepare ERC20 mocked tokens...
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

        await deployer.deploy(MiltonFaucet);

        miltonFaucet = await MiltonFaucet.deployed();
        miltonFaucetAddr = await miltonFaucet.address;
        miltonFaucet.sendTransaction({from: admin, value: "500000000000000000000000"});

        await deployer.deploy(MiltonDevToolDataProvider, iporAddressesManagerAddr);

        await deployer.link(AmmMath, WarrenDevToolDataProvider);
        await deployer.deploy(WarrenDevToolDataProvider, iporAddressesManagerAddr);

        await deployer.deploy(IpToken, mockedUsdtAddr, "IP USDT", "ipUSDT");
        ipUsdtToken = await IpToken.deployed();
        await deployer.deploy(IpToken, mockedUsdcAddr, "IP USDC", "ipUSDC");
        ipUsdcToken = await IpToken.deployed();
        await deployer.deploy(IpToken, mockedDaiAddr, "IP DAI", "ipDAI");
        ipDaiToken = await IpToken.deployed();

        await iporAddressesManager.addAsset(mockedDaiAddr);
        await iporAddressesManager.addAsset(mockedUsdtAddr);
        await iporAddressesManager.addAsset(mockedUsdcAddr);
        await iporAddressesManager.setIpToken(mockedUsdtAddr, ipUsdtToken.address);
        await iporAddressesManager.setIpToken(mockedUsdcAddr, ipUsdcToken.address);
        await iporAddressesManager.setIpToken(mockedDaiAddr, ipDaiToken.address);

        await ipUsdtToken.initialize(iporAddressesManager.address);
        await ipUsdcToken.initialize(iporAddressesManager.address);
        await ipDaiToken.initialize(iporAddressesManager.address);

        await deployer.deploy(IporConfiguration, mockedUsdtAddr);
        iporConfigurationUsdt = await IporConfiguration.deployed();

        await deployer.deploy(IporConfiguration, mockedUsdcAddr);
        iporConfigurationUsdc = await IporConfiguration.deployed();

        await deployer.deploy(IporConfiguration, mockedDaiAddr);
        iporConfigurationDai = await IporConfiguration.deployed();

        await iporConfigurationUsdt.initialize(iporAddressesManagerAddr);
        await iporConfigurationUsdc.initialize(iporAddressesManagerAddr);
        await iporConfigurationDai.initialize(iporAddressesManagerAddr);
    } else {

        //only public network - test and production
        if (_network !== 'test') {
            await iporAddressesManager.addAsset(process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS);
            await iporAddressesManager.addAsset(process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS);
            await iporAddressesManager.addAsset(process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS);
            await miltonStorage.addAsset(process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS);
            await miltonStorage.addAsset(process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS);
            await miltonStorage.addAsset(process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS);

            await deployer.deploy(IpToken, process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS, "IP USDT", "ipUSDT");
            ipUsdtToken = await IpToken.deployed();
            await deployer.deploy(IpToken, process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS, "IP USDC", "ipUSDC");
            ipUsdcToken = await IpToken.deployed();
            await deployer.deploy(IpToken, process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS, "IP DAI", "ipDAI");
            ipDaiToken = await IpToken.deployed();


            await deployer.deploy(IporConfiguration, process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS);
            iporConfigurationUsdt = await IporConfiguration.deployed();

            await deployer.deploy(IporConfiguration, process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS);
            iporConfigurationUsdc = await IporConfiguration.deployed();

            await deployer.deploy(IporConfiguration, process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS);
            iporConfigurationDai = await IporConfiguration.deployed();

            await iporAddressesManager.addAsset(mockedDaiAddr);
            await iporAddressesManager.addAsset(mockedUsdtAddr);
            await iporAddressesManager.addAsset(mockedUsdcAddr);

            await iporAddressesManager.setIpToken(process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS, ipUsdtToken.address);
            await iporAddressesManager.setIpToken(process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS, ipUsdcToken.address);
            await iporAddressesManager.setIpToken(process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS, ipDaiToken.address);

            await iporConfigurationUsdt.initialize(iporAddressesManagerAddr);
            await iporConfigurationUsdc.initialize(iporAddressesManagerAddr);
            await iporConfigurationDai.initialize(iporAddressesManagerAddr);
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

        await deployer.link(AmmMath, Joseph);
        await deployer.deploy(Joseph);
        joseph = await Joseph.deployed();

        await deployer.deploy(MiltonStorage);
        miltonStorage = await MiltonStorage.deployed();

        warrenAddr = await warren.address;
        miltonAddr = await milton.address;
        miltonStorageAddr = await miltonStorage.address;

        //initial addresses setup
        await iporAddressesManager.setAddress(keccak256("WARREN"), warrenAddr);
        await iporAddressesManager.setAddress(keccak256("WARREN_STORAGE"), warrenStorageAddr);
        await iporAddressesManager.setAddress(keccak256("MILTON_STORAGE"), miltonStorageAddr);


        if (isTestEnvironment == 1) {
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

            //TestJoseph
            await deployer.link(AmmMath, TestJoseph);
            await deployer.deploy(TestJoseph);
            testJoseph = await TestJoseph.deployed();

            if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {
                if (process.env.PRIV_TEST_NETWORK_USE_TEST_MILTON === "true") {
                    //For IPOR Test Framework purposes
                    await iporAddressesManager.setAddress(keccak256("MILTON"), testMilton.address);
                } else {
                    //Web application, IPOR Dev Tool
                    await iporAddressesManager.setAddress(keccak256("MILTON"), miltonAddr);
                }

                if (process.env.PRIV_TEST_NETWORK_USE_TEST_JOSEPH === "true") {
                    //For IPOR Test Framework purposes
                    await iporAddressesManager.setAddress(keccak256("JOSEPH"), testJoseph.address);
                } else {
                    //Web application, IPOR Dev Tool
                    await iporAddressesManager.setAddress(keccak256("JOSEPH"), joseph.address);
                }
            } else {
                await iporAddressesManager.setAddress(keccak256("MILTON"), miltonAddr);
                await iporAddressesManager.setAddress(keccak256("JOSEPH"), joseph.address);
            }

            await testMilton.initialize(iporAddressesManagerAddr);
            await testJoseph.initialize(iporAddressesManagerAddr);

        } else {
            await iporAddressesManager.setAddress(keccak256("MILTON"), miltonAddr);
        }

        await milton.initialize(iporAddressesManagerAddr);
        await miltonStorage.initialize(iporAddressesManagerAddr);
        await joseph.initialize(iporAddressesManagerAddr);

    } else {
        await deployer.link(AmmMath, TestWarren);
        await deployer.link(IporLogic, TestWarren);
        await deployer.link(DerivativeLogic, TestMilton);
        await deployer.link(AmmMath, TestMilton);
        await deployer.link(AmmMath, TestJoseph);
        await deployer.link(AmmMath, WarrenDevToolDataProvider);
        await deployer.deploy(WarrenDevToolDataProvider, iporAddressesManagerAddr);

    }

    //Prepare tokens for initial accounts...
    if (_network === 'develop' || _network === 'develop2' || _network === 'dev' || _network === 'docker') {
        console.log("Setup Faucet...");
        await mockedUsdt.transfer(miltonFaucetAddr, faucetSupply6Decimals);
        await mockedUsdc.transfer(miltonFaucetAddr, faucetSupply6Decimals);
        await mockedDai.transfer(miltonFaucetAddr, faucetSupply18Decimals);

        console.log("Setup Faucet finished.");

        console.log("Start transfer TOKENS to test addresses...");

        //first address is an admin, last two addresses will not have tokens and approves
        for (let i = 0; i < addresses.length - 2; i++) {
            await mockedUsdt.transfer(addresses[i], userSupply6Decimals);
            await mockedUsdc.transfer(addresses[i], userSupply6Decimals);
            await mockedDai.transfer(addresses[i], userSupply18Decimals);


            console.log(`Account: ${addresses[i]} - tokens transferred`);

            //Milton has rights to spend money on behalf of user
            //TODO: Use safeIncreaseAllowance() and safeDecreaseAllowance() from OpenZepppelin’s
            // SafeERC20 implementation to prevent race conditions from manipulating the allowance amounts.

            mockedUsdt.approve(miltonAddr, totalSupply6Decimals, {from: addresses[i]});
            mockedUsdc.approve(miltonAddr, totalSupply6Decimals, {from: addresses[i]});
            mockedDai.approve(miltonAddr, totalSupply18Decimals, {from: addresses[i]});

            mockedUsdt.approve(joseph.address, totalSupply6Decimals, {from: addresses[i]});
            mockedUsdc.approve(joseph.address, totalSupply6Decimals, {from: addresses[i]});
            mockedDai.approve(joseph.address, totalSupply18Decimals, {from: addresses[i]});

            console.log(`Account: ${addresses[i]} approve spender Milton ${miltonAddr} to spend tokens on behalf of user.`);
            console.log(`Account: ${addresses[i]} approve spender Joseph ${joseph.address} to spend tokens on behalf of user.`);

            if (isTestEnvironment) {

                mockedUsdt.approve(testMilton.address, totalSupply6Decimals, {from: addresses[i]});
                mockedUsdc.approve(testMilton.address, totalSupply6Decimals, {from: addresses[i]});
                mockedDai.approve(testMilton.address, totalSupply18Decimals, {from: addresses[i]});


                mockedUsdt.approve(testJoseph.address, totalSupply6Decimals, {from: addresses[i]});
                mockedUsdc.approve(testJoseph.address, totalSupply6Decimals, {from: addresses[i]});
                mockedDai.approve(testJoseph.address, totalSupply18Decimals, {from: addresses[i]});

                console.log(`Account: ${addresses[i]} approve spender TestMilton ${testMilton.address} to spend tokens on behalf of user.`);
                console.log(`Account: ${addresses[i]} approve spender TestJoseph ${testJoseph.address} to spend tokens on behalf of user.`);
            }
        }

        await milton.authorizeJoseph(mockedUsdt.address);
        await milton.authorizeJoseph(mockedUsdc.address);
        await milton.authorizeJoseph(mockedDai.address);

        await testMilton.authorizeJoseph(mockedUsdt.address);
        await testMilton.authorizeJoseph(mockedUsdc.address);
        await testMilton.authorizeJoseph(mockedDai.address);

        await miltonStorage.addAsset(mockedDaiAddr);
        await miltonStorage.addAsset(mockedUsdcAddr);
        await miltonStorage.addAsset(mockedUsdtAddr);

    }

    await miltonLPUtilizationStrategyCollateral.initialize(iporAddressesManagerAddr);
    await miltonSpreadStrategy.initialize(iporAddressesManagerAddr);
};
