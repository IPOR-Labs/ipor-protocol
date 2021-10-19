require('dotenv').config({path: '../.env'})

const Warren = artifacts.require("Warren");
const WarrenStorage = artifacts.require("WarrenStorage");
const Milton = artifacts.require("Milton");
const MiltonStorage = artifacts.require("MiltonStorage");
const MiltonFaucet = artifacts.require("MiltonFaucet");
const TestWarren = artifacts.require("TestWarren");
const TestMilton = artifacts.require("TestMilton");
const TestJoseph = artifacts.require("TestJoseph");
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
    let mockedTusd = null;
    let mockedTusdAddr = null;
    let warrenAddr = null;
    let milton = null;
    let testMilton = null;
    let testJoseph = null;
    let miltonAddr = null;
    let miltonStorage = null;
    let miltonStorageAddr = null;
    let miltonFaucet = null;
    let miltonFaucetAddr = null;
    let iporConfiguration = null;
    let iporAddressesManager = null;
    let joseph = null;

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

    await deployer.deploy(IporConfiguration);
    iporConfiguration = await IporConfiguration.deployed();

    await deployer.deploy(IporAddressesManager);
    iporAddressesManager = await IporAddressesManager.deployed();
    let iporAddressesManagerAddr = await iporAddressesManager.address;

    await deployer.deploy(MiltonFrontendDataProvider, iporAddressesManagerAddr);

    await deployer.link(AmmMath, WarrenFrontendDataProvider);
    await deployer.deploy(WarrenFrontendDataProvider, iporAddressesManagerAddr);

    await deployer.link(AmmMath, MiltonLPUtilizationStrategyCollateral);
    await deployer.deploy(MiltonLPUtilizationStrategyCollateral);
    let miltonLPUtilizationStrategyCollateral = await MiltonLPUtilizationStrategyCollateral.deployed();
    await iporAddressesManager.setAddress("MILTON_UTILIZATION_STRATEGY", miltonLPUtilizationStrategyCollateral.address);

    await deployer.deploy(MiltonSpreadStrategy);
    let miltonSpreadStrategy = await MiltonSpreadStrategy.deployed();
    await iporAddressesManager.setAddress("MILTON_SPREAD_STRATEGY", miltonSpreadStrategy.address);

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

        await deployer.deploy(TusdMockedToken, totalSupply18Decimals, 18);
        mockedTusd = await TusdMockedToken.deployed();
        mockedTusdAddr = await mockedTusd.address;

        await deployer.deploy(MiltonFaucet);

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

        await ipUsdtToken.initialize(iporAddressesManager.address);
        await ipUsdcToken.initialize(iporAddressesManager.address);
        await ipDaiToken.initialize(iporAddressesManager.address);

    } else {

        //only public network - test and production
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

            await iporAddressesManager.addAsset(process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS);
            await iporAddressesManager.addAsset(process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS);
            await iporAddressesManager.addAsset(process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS);

            await miltonStorage.addAsset(process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS);
            await miltonStorage.addAsset(process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS);
            await miltonStorage.addAsset(process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS);
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
        const iporConfigurationAddr = await iporConfiguration.address;

        //initial addresses setup
        await iporAddressesManager.setAddress("WARREN", warrenAddr);
        await iporAddressesManager.setAddress("WARREN_STORAGE", warrenStorageAddr);
        await iporAddressesManager.setAddress("MILTON_STORAGE", miltonStorageAddr);
        await iporAddressesManager.setAddress("IPOR_CONFIGURATION", iporConfigurationAddr);

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
                    await iporAddressesManager.setAddress("MILTON", testMilton.address);
                } else {
                    //Web application, IPOR Dev Tool
                    await iporAddressesManager.setAddress("MILTON", miltonAddr);
                }

                if (process.env.PRIV_TEST_NETWORK_USE_TEST_JOSEPH === "true") {
                    //For IPOR Test Framework purposes
                    await iporAddressesManager.setAddress("JOSEPH", testJoseph.address);
                } else {
                    //Web application, IPOR Dev Tool
                    await iporAddressesManager.setAddress("JOSEPH", joseph.address);
                }
            } else {
                await iporAddressesManager.setAddress("MILTON", miltonAddr);
                await iporAddressesManager.setAddress("JOSEPH", joseph.address);
            }

            await testMilton.initialize(iporAddressesManagerAddr);
            await testJoseph.initialize(iporAddressesManagerAddr);

        } else {
            await iporAddressesManager.setAddress("MILTON", miltonAddr);
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
        await deployer.deploy(MiltonDevToolDataProvider, iporAddressesManagerAddr);
        await deployer.link(AmmMath, WarrenDevToolDataProvider);
        await deployer.deploy(WarrenDevToolDataProvider, iporAddressesManagerAddr);

    }

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

            //Milton has rights to spend money on behalf of user
            //TODO: Use safeIncreaseAllowance() and safeDecreaseAllowance() from OpenZepppelin’s SafeERC20 implementation to prevent race conditions from manipulating the allowance amounts.
            mockedUsdt.approve(miltonAddr, totalSupply6Decimals, {from: addresses[i]});
            mockedUsdc.approve(miltonAddr, totalSupply6Decimals, {from: addresses[i]});
            mockedDai.approve(miltonAddr, totalSupply18Decimals, {from: addresses[i]});
            mockedTusd.approve(miltonAddr, totalSupply18Decimals, {from: addresses[i]});

            mockedUsdt.approve(joseph.address, totalSupply6Decimals, {from: addresses[i]});
            mockedUsdc.approve(joseph.address, totalSupply6Decimals, {from: addresses[i]});
            mockedDai.approve(joseph.address, totalSupply18Decimals, {from: addresses[i]});
            mockedTusd.approve(joseph.address, totalSupply18Decimals, {from: addresses[i]});

            console.log(`Account: ${addresses[i]} approve spender Milton ${miltonAddr} to spend tokens on behalf of user.`);
            console.log(`Account: ${addresses[i]} approve spender Joseph ${joseph.address} to spend tokens on behalf of user.`);

            if (isTestEnvironment) {
                mockedUsdt.approve(testMilton.address, totalSupply6Decimals, {from: addresses[i]});
                mockedUsdc.approve(testMilton.address, totalSupply6Decimals, {from: addresses[i]});
                mockedDai.approve(testMilton.address, totalSupply18Decimals, {from: addresses[i]});
                mockedTusd.approve(testMilton.address, totalSupply18Decimals, {from: addresses[i]});

                mockedUsdt.approve(testJoseph.address, totalSupply6Decimals, {from: addresses[i]});
                mockedUsdc.approve(testJoseph.address, totalSupply6Decimals, {from: addresses[i]});
                mockedDai.approve(testJoseph.address, totalSupply18Decimals, {from: addresses[i]});
                mockedTusd.approve(testJoseph.address, totalSupply18Decimals, {from: addresses[i]});

                console.log(`Account: ${addresses[i]} approve spender TestMilton ${testMilton} to spend tokens on behalf of user.`);
                console.log(`Account: ${addresses[i]} approve spender TestJoseph ${testJoseph} to spend tokens on behalf of user.`);
            }
        }

        await milton.authorizeLiquidityPool(mockedUsdt.address);
        await milton.authorizeLiquidityPool(mockedUsdc.address);
        await milton.authorizeLiquidityPool(mockedDai.address);
        await milton.authorizeLiquidityPool(mockedTusd.address);

        await testMilton.authorizeLiquidityPool(mockedUsdt.address);
        await testMilton.authorizeLiquidityPool(mockedUsdc.address);
        await testMilton.authorizeLiquidityPool(mockedDai.address);
        await testMilton.authorizeLiquidityPool(mockedTusd.address);

        console.log("Initialize Milton Storage assets...");
        await iporAddressesManager.addAsset(mockedDaiAddr);
        await iporAddressesManager.addAsset(mockedUsdtAddr);
        await iporAddressesManager.addAsset(mockedUsdcAddr);

        await miltonStorage.addAsset(mockedDaiAddr);
        await miltonStorage.addAsset(mockedUsdcAddr);
        await miltonStorage.addAsset(mockedUsdtAddr);

    }

    await miltonLPUtilizationStrategyCollateral.initialize(iporAddressesManagerAddr);
    await miltonSpreadStrategy.initialize(iporAddressesManagerAddr);
    await iporConfiguration.initialize(iporAddressesManagerAddr);
};
