const keccak256 = require("keccak256");
const TestJoseph = artifacts.require('TestJoseph');
const TestMilton = artifacts.require('TestMilton');
const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const IporAssetConfigurationUsdt = artifacts.require('IporAssetConfigurationUsdt');
const IporAssetConfigurationUsdc = artifacts.require('IporAssetConfigurationUsdc');
const IporAssetConfigurationDai = artifacts.require('IporAssetConfigurationDai');
const IporConfiguration = artifacts.require('IporConfiguration');
const MiltonStorage = artifacts.require('MiltonStorage');
const TestWarren = artifacts.require('TestWarren');
const WarrenStorage = artifacts.require('WarrenStorage');
const IpToken = artifacts.require('IpToken');
const MiltonDevToolDataProvider = artifacts.require('MiltonDevToolDataProvider');

module.exports.assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error), `Expected exception with message ${error} but actual error message: ${e.message}`)
        return;
    }
    assert(false);
}

module.exports.ZERO = BigInt("0");
module.exports.PERIOD_1_DAY_IN_SECONDS = 60 * 60 * 24 * 1;
module.exports.PERIOD_14_DAYS_IN_SECONDS = 60 * 60 * 24 * 14;
module.exports.PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;
module.exports.PERIOD_28_DAYS_IN_SECONDS = 60 * 60 * 24 * 28;
module.exports.PERIOD_50_DAYS_IN_SECONDS = 60 * 60 * 24 * 50;
module.exports.USD_10_18DEC = BigInt("10000000000000000000");
module.exports.USD_10_6DEC = BigInt("10000000");
module.exports.USD_20_18DEC = BigInt("20000000000000000000");
module.exports.USD_20_6DEC = BigInt("20000000");
module.exports.USD_99__7_18DEC = BigInt("99700000000000000000")
module.exports.USD_9063__63_18DEC = BigInt("9063636363636363636364");//9063,(63) USD
module.exports.USD_906__36_18DEC = BigInt("906363636363636363636");//906,(36) USD
module.exports.USD_9063__63_6DEC = BigInt("9063636364");//9063,(63) USD
module.exports.USD_906__36_6DEC = BigInt("906363636");//906,(36) USD
module.exports.USD_10_000_18DEC = BigInt("10000000000000000000000");
module.exports.USD_10_000_6DEC = BigInt("10000000000");
module.exports.USD_10_400_18DEC = BigInt("10400000000000000000000");
module.exports.USD_14_000_18DEC = BigInt("14000000000000000000000");
module.exports.USD_14_000_6DEC = BigInt("14000000000");
module.exports.USD_10_000_000_18DEC = BigInt("10000000000000000000000000");
module.exports.USD_10_000_000_6DEC = BigInt("10000000000000");
module.exports.PERCENTAGE_3_18DEC = BigInt("30000000000000000");
module.exports.PERCENTAGE_3_6DEC = BigInt("30000");
module.exports.PERCENTAGE_5_18DEC = BigInt("50000000000000000");
module.exports.PERCENTAGE_5_6DEC = BigInt("50000");
module.exports.PERCENTAGE_6_18DEC = BigInt("60000000000000000");
module.exports.PERCENTAGE_6_6DEC = BigInt("60000");
module.exports.PERCENTAGE_10_18DEC = BigInt("100000000000000000");
module.exports.PERCENTAGE_20_18DEC = BigInt("200000000000000000");
module.exports.PERCENTAGE_50_18DEC = BigInt("500000000000000000");
module.exports.PERCENTAGE_100_18DEC = BigInt("1000000000000000000");
module.exports.PERCENTAGE_120_18DEC = BigInt("1200000000000000000");
module.exports.PERCENTAGE_120_6DEC = BigInt("1200000");
module.exports.PERCENTAGE_160_18DEC = BigInt("1600000000000000000");
module.exports.PERCENTAGE_160_6DEC = BigInt("1600000");
module.exports.PERCENTAGE_365_18DEC = BigInt("3650000000000000000");
module.exports.PERCENTAGE_365_6DEC = BigInt("3650000");

module.exports.TOTAL_SUPPLY_6_DECIMALS = BigInt('100000000000000000000');
module.exports.TOTAL_SUPPLY_18_DECIMALS = BigInt('10000000000000000000000000000000000');
module.exports.USER_SUPPLY_6_DECIMALS = BigInt('10000000000000');
module.exports.USER_SUPPLY_18_DECIMALS = BigInt('10000000000000000000000000');
module.exports.COLLATERALIZATION_FACTOR_18DEC = BigInt('10000000000000000000');
module.exports.COLLATERALIZATION_FACTOR_6DEC = BigInt('10000000');

//data for Test Cases
module.exports.TC_MULTIPLICATOR_18DEC = BigInt(1e18);
module.exports.TC_MULTIPLICATOR_6DEC = BigInt(1e6);
module.exports.TC_IBT_PRICE_DAI_18DEC = BigInt(1e18);
module.exports.TC_IBT_PRICE_DAI_6DEC = BigInt(1e6);
module.exports.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC = BigInt("20000000000000000000");
module.exports.TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC = BigInt("20000000");
module.exports.TC_IPOR_PUBLICATION_AMOUNT_18DEC = BigInt("10000000000000000000");
module.exports.TC_IPOR_PUBLICATION_AMOUNT_6DEC = BigInt("10000000");
module.exports.TC_LP_BALANCE_BEFORE_CLOSE_18DEC = BigInt("14000000000000000000000");
module.exports.TC_LP_BALANCE_BEFORE_CLOSE_6DEC = BigInt("14000000000");
module.exports.TC_TOTAL_AMOUNT = BigInt("10000000000000000000000");
module.exports.TC_COLLATERAL_18DEC = BigInt("9063636363636363636364");
module.exports.TC_COLLATERAL_6DEC = BigInt("9063636364");
module.exports.TC_OPENING_FEE_18DEC = BigInt("906363636363636363636");
module.exports.TC_OPENING_FEE_6DEC = BigInt("906363636");
const {
    TOTAL_SUPPLY_6_DECIMALS,
    TOTAL_SUPPLY_18_DECIMALS,
    USD_10_000_18DEC,
    ZERO,
    USER_SUPPLY_18_DECIMALS, USER_SUPPLY_6_DECIMALS, USD_10_000_6DEC, COLLATERALIZATION_FACTOR_18DEC
} = require("./TestUtils");
//specific data
module.exports.SPECIFIC_INCOME_TAX_CASE_1 = BigInt("579079452054794521914");
module.exports.SPECIFIC_INTEREST_AMOUNT_CASE_1 = BigInt("5790794520547945219137");

module.exports.pad32Bytes = (data) => {
    var s = String(data);
    while (s.length < (64 || 2)) {
        s = "0" + s;
    }
    return s;
}

module.exports.getStandardDerivativeParamsDAI = (user, testData) => {
    return {
        asset: testData.tokenDai.address,
        totalAmount: USD_10_000_18DEC,
        slippageValue: 3,
        collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user
    }
}
module.exports.getStandardDerivativeParamsUSDT = (user, testData) => {
    return {
        asset: testData.tokenUsdt.address,
        totalAmount: USD_10_000_6DEC,
        slippageValue: 3,
        collateralizationFactor: BigInt(10000000),
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user
    }
}

module.exports.setupTokenDaiInitialValuesForUsers = async (users, testData) => {
    for (let i = 0; i < users.length; i++) {
        await testData.tokenDai.setupInitialAmount(users[i], USER_SUPPLY_18_DECIMALS);
    }
}
module.exports.setupTokenUsdtInitialValuesForUsers = async (users, testData) => {
    for (let i = 0; i < users.length; i++) {
        await testData.tokenUsdt.setupInitialAmount(users[i], USER_SUPPLY_6_DECIMALS);
    }
}
module.exports.setupTokenUsdcInitialValuesForUsers = async (users, testData) => {
    for (let i = 0; i < users.length; i++) {
        await testData.tokenUsdc.setupInitialAmount(users[i], USER_SUPPLY_6_DECIMALS);
    }
}

module.exports.setupIpTokenDaiInitialValues = async (liquidityProvider, initialAmount) => {

    if (initialAmount > 0) {
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), liquidityProvider);
        await data.ipTokenDai.mint(liquidityProvider, initialAmount, {from: liquidityProvider});
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);
    }
}

module.exports.setupIpTokenUsdtInitialValues = async (liquidityProvider, initialAmount) => {

    if (initialAmount > 0) {
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), liquidityProvider);
        await data.ipTokenUsdt.mint(liquidityProvider, initialAmount, {from: liquidityProvider});
        await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);
    }
}

module.exports.prepareApproveForUsers = async (users, asset, data, testData) => {
    for (let i = 0; i < users.length; i++) {
        if (asset === "USDT") {
            await testData.tokenUsdt.approve(data.joseph.address, TOTAL_SUPPLY_6_DECIMALS, {from: users[i]});
            await testData.tokenUsdt.approve(data.milton.address, TOTAL_SUPPLY_6_DECIMALS, {from: users[i]});
        }
        if (asset === "USDC") {
            await testData.tokenUsdc.approve(data.joseph.address, TOTAL_SUPPLY_6_DECIMALS, {from: users[i]});
            await testData.tokenUsdc.approve(data.milton.address, TOTAL_SUPPLY_6_DECIMALS, {from: users[i]});
        }
        if (asset === "DAI") {
            await testData.tokenDai.approve(data.joseph.address, TOTAL_SUPPLY_18_DECIMALS, {from: users[i]});
            await testData.tokenDai.approve(data.milton.address, TOTAL_SUPPLY_18_DECIMALS, {from: users[i]});
        }
    }
}

module.exports.prepareData = async () => {

    let iporConfiguration = await IporConfiguration.deployed();
    let miltonDevToolDataProvider = await MiltonDevToolDataProvider.new(iporConfiguration.address);
    let warren = await TestWarren.new();
    let milton = await TestMilton.new();
    let joseph = await TestJoseph.new();

    await iporConfiguration.setAddress(keccak256("WARREN"), await warren.address);
    await iporConfiguration.setAddress(keccak256("MILTON"), await milton.address);
    await iporConfiguration.setAddress(keccak256("JOSEPH"), await joseph.address);

    await warren.initialize(iporConfiguration.address);
    await milton.initialize(iporConfiguration.address);
    await joseph.initialize(iporConfiguration.address);

    let data = {
        warren: warren,
        milton: milton,
        joseph: joseph,
        iporConfiguration: iporConfiguration,
        miltonDevToolDataProvider: miltonDevToolDataProvider
    }

    return data;
}
module.exports.prepareTestData = async (accounts, assets, data) => {

    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let ipTokenUsdt = null;
    let ipTokenUsdc = null;
    let ipTokenDai = null;
    let iporAssetConfigurationUsdt = null;
    let iporAssetConfigurationUsdc = null;
    let iporAssetConfigurationDai = null;

    let miltonStorage = await MiltonStorage.new();
    let warrenStorage = await WarrenStorage.new();

    await warrenStorage.addUpdater(accounts[1]);
    await warrenStorage.addUpdater(data.warren.address);

    await data.iporConfiguration.setAddress(keccak256("MILTON_STORAGE"), miltonStorage.address);
    await data.iporConfiguration.setAddress(keccak256("WARREN_STORAGE"), warrenStorage.address);

    await miltonStorage.initialize(data.iporConfiguration.address);
    await warrenStorage.initialize(data.iporConfiguration.address);

    for (let k = 0; k < assets.length; k++) {
        if (assets[k] === "USDT") {
            tokenUsdt = await UsdtMockedToken.new(TOTAL_SUPPLY_6_DECIMALS, 6);
            await data.iporConfiguration.addAsset(tokenUsdt.address);
            await data.milton.authorizeJoseph(tokenUsdt.address);
            ipTokenUsdt = await IpToken.new(tokenUsdt.address, "IP USDT", "ipUSDT");
            ipTokenUsdt.initialize(data.iporConfiguration.address);
            iporAssetConfigurationUsdt = await IporAssetConfigurationUsdt.new(tokenUsdt.address, ipTokenUsdt.address);
            await data.iporConfiguration.setIporAssetConfiguration(tokenUsdt.address, await iporAssetConfigurationUsdt.address);
            await miltonStorage.addAsset(tokenUsdt.address);
        }
        if (assets[k] === "USDC") {
            tokenUsdc = await UsdcMockedToken.new(TOTAL_SUPPLY_6_DECIMALS, 6);
            await data.iporConfiguration.addAsset(tokenUsdc.address);
            await data.milton.authorizeJoseph(tokenUsdc.address);
            ipTokenUsdc = await IpToken.new(tokenUsdc.address, "IP USDC", "ipUSDC");
            ipTokenUsdc.initialize(data.iporConfiguration.address);
            iporAssetConfigurationUsdc = await IporAssetConfigurationUsdc.new(tokenUsdc.address, ipTokenUsdc.address);
            await data.iporConfiguration.setIporAssetConfiguration(tokenUsdc.address, await iporAssetConfigurationUsdc.address);
            await miltonStorage.addAsset(tokenUsdc.address);
        }
        if (assets[k] === "DAI") {
            tokenDai = await DaiMockedToken.new(TOTAL_SUPPLY_18_DECIMALS, 18);
            await data.iporConfiguration.addAsset(tokenDai.address);
            await data.milton.authorizeJoseph(tokenDai.address);
            ipTokenDai = await IpToken.new(tokenDai.address, "IP DAI", "ipDAI");
            ipTokenDai.initialize(data.iporConfiguration.address);
            iporAssetConfigurationDai = await IporAssetConfigurationDai.new(tokenDai.address, ipTokenDai.address);
            await data.iporConfiguration.setIporAssetConfiguration(tokenDai.address, await iporAssetConfigurationDai.address);
            await miltonStorage.addAsset(tokenDai.address);
        }
    }

    let testData = {
        tokenDai: tokenDai,
        tokenUsdt: tokenUsdt,
        tokenUsdc: tokenUsdc,
        ipTokenUsdt: ipTokenUsdt,
        ipTokenUsdc: ipTokenUsdc,
        ipTokenDai: ipTokenDai,
        iporAssetConfigurationUsdt: iporAssetConfigurationUsdt,
        iporAssetConfigurationUsdc: iporAssetConfigurationUsdc,
        iporAssetConfigurationDai: iporAssetConfigurationDai,
        miltonStorage: miltonStorage,
        warrenStorage: warrenStorage
    }
    return testData;
}
