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

module.exports.getStandardDerivativeParamsDAI = (data) => {
    return {
        asset: data.tokenDai.address,
        totalAmount: USD_10_000_18DEC,
        slippageValue: 3,
        collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: data.userTwo
    }
}
module.exports.getStandardDerivativeParamsUSDT = (data) => {
    return {
        asset: data.tokenUsdt.address,
        totalAmount: USD_10_000_6DEC,
        slippageValue: 3,
        collateralizationFactor: BigInt(10000000),
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: data.userTwo
    }
}

module.exports.setupTokenUsdtInitialValues = async (data) => {
    await data.tokenUsdt.setupInitialAmount(await data.milton.address, ZERO);
    await data.tokenUsdt.setupInitialAmount(data.admin, USER_SUPPLY_6_DECIMALS);
    await data.tokenUsdt.setupInitialAmount(data.userOne, USER_SUPPLY_6_DECIMALS);
    await data.tokenUsdt.setupInitialAmount(data.userTwo, USER_SUPPLY_6_DECIMALS);
    await data.tokenUsdt.setupInitialAmount(data.userThree, USER_SUPPLY_6_DECIMALS);
    await data.tokenUsdt.setupInitialAmount(data.liquidityProvider, USER_SUPPLY_6_DECIMALS);
}
module.exports.setupTokenUsdcInitialValues = async (data) => {
    await data.tokenUsdc.setupInitialAmount(await data.milton.address, ZERO);
    await data.tokenUsdc.setupInitialAmount(data.admin, USER_SUPPLY_6_DECIMALS);
    await data.tokenUsdc.setupInitialAmount(data.userOne, USER_SUPPLY_6_DECIMALS);
    await data.tokenUsdc.setupInitialAmount(data.userTwo, USER_SUPPLY_6_DECIMALS);
    await data.tokenUsdc.setupInitialAmount(data.userThree, USER_SUPPLY_6_DECIMALS);
    await data.tokenUsdc.setupInitialAmount(data.liquidityProvider, USER_SUPPLY_6_DECIMALS);
}

module.exports.setupTokenDaiInitialValues = async (data) => {
    await data.tokenDai.setupInitialAmount(await data.milton.address, ZERO);
    await data.tokenDai.setupInitialAmount(data.admin, USER_SUPPLY_18_DECIMALS);
    await data.tokenDai.setupInitialAmount(data.userOne, USER_SUPPLY_18_DECIMALS);
    await data.tokenDai.setupInitialAmount(data.userTwo, USER_SUPPLY_18_DECIMALS);
    await data.tokenDai.setupInitialAmount(data.userThree, USER_SUPPLY_18_DECIMALS);
    await data.tokenDai.setupInitialAmount(data.liquidityProvider, USER_SUPPLY_18_DECIMALS);
}
module.exports.setupTokenDaiInitialZeroValues = async (data) => {
    await data.tokenDai.setupInitialAmount(await data.milton.address, ZERO);
    await data.tokenDai.setupInitialAmount(data.admin, ZERO);
    await data.tokenDai.setupInitialAmount(data.userOne, ZERO);
    await data.tokenDai.setupInitialAmount(data.userTwo, ZERO);
    await data.tokenDai.setupInitialAmount(data.userThree, ZERO);
    await data.tokenDai.setupInitialAmount(data.liquidityProvider, ZERO);
}

module.exports.setupIpTokenDaiInitialValues = async (data, initialAmount) => {
    await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.userOne);
    let lpBalance = BigInt(await data.ipTokenDai.balanceOf(data.liquidityProvider));
    if (lpBalance > 0) {
        await data.ipTokenDai.burn(data.liquidityProvider, data.userFive, lpBalance, {from: data.userOne});
    }
    if (initialAmount > 0) {
        await data.ipTokenDai.mint(data.liquidityProvider, initialAmount, {from: data.userOne});
    }
    await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);
}

module.exports.setupIpTokenUsdcInitialValues = async (data, initialAmount) => {
    await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.userOne);
    let lpBalance = BigInt(await data.ipTokenUsdc.balanceOf(data.liquidityProvider));
    if (lpBalance > 0) {
        await data.ipTokenUsdc.burn(data.liquidityProvider, data.userFive, lpBalance, {from: data.userOne});
    }
    if (initialAmount > 0) {
        await data.ipTokenUsdc.mint(data.liquidityProvider, initialAmount, {from: data.userOne});
    }
    await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);
}

module.exports.setupIpTokenUsdtInitialValues = async (data, testData) => {
    await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.userOne);
    let lpBalance = BigInt(await data.ipTokenUsdt.balanceOf(data.liquidityProvider));
    if (lpBalance > 0) {
        await data.ipTokenUsdt.burn(data.liquidityProvider, data.userFive, lpBalance, {from: data.userOne});
    }
    await data.iporConfiguration.setAddress(keccak256("JOSEPH"), data.joseph.address);
}


module.exports.clearTokenUsdt = async (data) => {
    await data.tokenUsdt.setupInitialAmount(await data.milton.address, ZERO);
    await data.tokenUsdt.setupInitialAmount(data.admin, ZERO);
    await data.tokenUsdt.setupInitialAmount(data.userOne, ZERO);
    await data.tokenUsdt.setupInitialAmount(data.userTwo, ZERO);
    await data.tokenUsdt.setupInitialAmount(data.userThree, ZERO);
    await data.tokenUsdt.setupInitialAmount(data.liquidityProvider, ZERO);
}

module.exports.prepareDataForBefore = async (accounts) => {
    let iporConfiguration = await IporConfiguration.deployed();

    let warren = await TestWarren.new();
    let milton = await TestMilton.new();
    let joseph = await TestJoseph.new();

    let tokenUsdt = await UsdtMockedToken.new(TOTAL_SUPPLY_6_DECIMALS, 6);
    let tokenUsdc = await UsdcMockedToken.new(TOTAL_SUPPLY_6_DECIMALS, 6);
    let tokenDai = await DaiMockedToken.new(TOTAL_SUPPLY_18_DECIMALS, 18);

    await iporConfiguration.addAsset(tokenUsdt.address);
    await iporConfiguration.addAsset(tokenUsdc.address);
    await iporConfiguration.addAsset(tokenDai.address);

    for (let i = 1; i < accounts.length - 2; i++) {
        //Liquidity Pool has rights to spend money on behalf of user accounts[i]
        await tokenUsdt.approve(joseph.address, TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
        await tokenUsdc.approve(joseph.address, TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
        await tokenDai.approve(joseph.address, TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});

        //Milton has rights to spend money on behalf of user accounts[i]
        await tokenUsdt.approve(milton.address, TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
        await tokenUsdc.approve(milton.address, TOTAL_SUPPLY_6_DECIMALS, {from: accounts[i]});
        await tokenDai.approve(milton.address, TOTAL_SUPPLY_18_DECIMALS, {from: accounts[i]});
    }

    await iporConfiguration.setAddress(keccak256("WARREN"), await warren.address);
    await iporConfiguration.setAddress(keccak256("MILTON"), await milton.address);
    await iporConfiguration.setAddress(keccak256("JOSEPH"), await joseph.address);


    await warren.initialize(iporConfiguration.address);
    await milton.initialize(iporConfiguration.address);
    await joseph.initialize(iporConfiguration.address);

    await milton.authorizeJoseph(tokenDai.address);
    await milton.authorizeJoseph(tokenUsdc.address);
    await milton.authorizeJoseph(tokenUsdt.address);


    let ipTokenUsdt = await IpToken.new(tokenUsdt.address, "IP USDT", "ipUSDT");
    let ipTokenUsdc = await IpToken.new(tokenUsdc.address, "IP USDC", "ipUSDC");
    let ipTokenDai = await IpToken.new(tokenDai.address, "IP DAI", "ipDAI");

    ipTokenUsdt.initialize(iporConfiguration.address);
    ipTokenUsdc.initialize(iporConfiguration.address);
    ipTokenDai.initialize(iporConfiguration.address);

    let iporAssetConfigurationUsdt = await IporAssetConfigurationUsdt.new(tokenUsdt.address, ipTokenUsdt.address);
    let iporAssetConfigurationUsdc = await IporAssetConfigurationUsdc.new(tokenUsdc.address, ipTokenUsdc.address);
    let iporAssetConfigurationDai = await IporAssetConfigurationDai.new(tokenDai.address, ipTokenDai.address);

    await iporAssetConfigurationUsdt.initialize(iporConfiguration.address);
    await iporAssetConfigurationUsdc.initialize(iporConfiguration.address);
    await iporAssetConfigurationDai.initialize(iporConfiguration.address);

    await iporConfiguration.setIporAssetConfiguration(tokenUsdt.address, await iporAssetConfigurationUsdt.address);
    await iporConfiguration.setIporAssetConfiguration(tokenUsdc.address, await iporAssetConfigurationUsdc.address);
    await iporConfiguration.setIporAssetConfiguration(tokenDai.address, await iporAssetConfigurationDai.address);

    let miltonDevToolDataProvider = await MiltonDevToolDataProvider.new(iporConfiguration.address);

    let data = {
        admin: accounts[0],
        userOne: accounts[1],
        userTwo: accounts[2],
        userThree: accounts[3],
        liquidityProvider: accounts[4],
        userFive: accounts[5],
        warren: warren,
        milton: milton,
        joseph: joseph,
        iporConfiguration: iporConfiguration,
        tokenDai: tokenDai,
        tokenUsdt: tokenUsdt,
        tokenUsdc: tokenUsdc,
        ipTokenUsdt: ipTokenUsdt,
        ipTokenUsdc: ipTokenUsdc,
        ipTokenDai: ipTokenDai,
        iporAssetConfigurationUsdt: iporAssetConfigurationUsdt,
        iporAssetConfigurationUsdc: iporAssetConfigurationUsdc,
        iporAssetConfigurationDai: iporAssetConfigurationDai,
        miltonDevToolDataProvider: miltonDevToolDataProvider
    }

    return data;
}

module.exports.prepareDataForBeforeEach = async (data) => {

    let miltonStorage = await MiltonStorage.new();
    let warrenStorage = await WarrenStorage.new();

    await data.iporConfiguration.setAddress(keccak256("MILTON_STORAGE"), miltonStorage.address);
    await data.iporConfiguration.setAddress(keccak256("WARREN_STORAGE"), warrenStorage.address);

    await warrenStorage.addUpdater(data.userOne);
    await warrenStorage.addUpdater(data.warren.address);

    await miltonStorage.initialize(data.iporConfiguration.address);

    await miltonStorage.addAsset(data.tokenDai.address);
    await miltonStorage.addAsset(data.tokenUsdc.address);
    await miltonStorage.addAsset(data.tokenUsdt.address);

    await warrenStorage.initialize(data.iporConfiguration.address);

    let testData = {
        miltonStorage: miltonStorage,
        warrenStorage: warrenStorage
    }
    return testData;
}