const keccak256 = require("keccak256");
const { expect } = require("chai");

const {
    COLLATERALIZATION_FACTOR_18DEC,
    TOTAL_SUPPLY_18_DECIMALS,
    TOTAL_SUPPLY_6_DECIMALS,
    USD_10_000_18DEC,
    USD_10_000_6DEC,
    USER_SUPPLY_10MLN_18DEC,
    USER_SUPPLY_6_DECIMALS,
} = require("./Const.js");
const { ethers } = require("hardhat");

BigInt.prototype.toJSON = function () {
    return this.toString();
};

module.exports.absValue = (value) => {
    if (Math.sign(value) === -1n) {
        return -value;
    }
    return value;
};

module.exports.assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        expect(
            e.message.includes(error),
            `Expected exception with message ${error} but actual error message: ${e.message}`
        ).to.be.true;
        return;
    }
    expect(false).to.be.true;
};

module.exports.getLibraries = async () => {
    const IporSwapLogic = await ethers.getContractFactory("IporSwapLogic");
    const iporSwapLogic = await IporSwapLogic.deploy();
    await iporSwapLogic.deployed();

    const SoapIndicatorLogic = await ethers.getContractFactory(
        "SoapIndicatorLogic"
    );
    const soapIndicatorLogic = await SoapIndicatorLogic.deploy();
    await soapIndicatorLogic.deployed();

    return {
        iporSwapLogic,
        soapIndicatorLogic,
    };
};

module.exports.getStandardDerivativeParamsDAI = (user, testData) => {
    return {
        asset: testData.tokenDai.address,
        totalAmount: USD_10_000_18DEC,
        slippageValue: 3,
        collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user,
    };
};

module.exports.getStandardDerivativeParamsUSDT = (user, testData) => {
    return {
        asset: testData.tokenUsdt.address,
        totalAmount: USD_10_000_6DEC,
        slippageValue: 3,
        collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user,
    };
};

module.exports.grantAllRoleIporAssetConfiguration = async (
    iporAssetConfiguration,
    accounts
) => {
    await iporAssetConfiguration.grantRole(
        keccak256("MILTON_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporAssetConfiguration.grantRole(
        keccak256("MILTON_ROLE"),
        accounts[0].address
    );

    await iporAssetConfiguration.grantRole(
        keccak256("MILTON_STORAGE_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporAssetConfiguration.grantRole(
        keccak256("MILTON_STORAGE_ROLE"),
        accounts[0].address
    );

    await iporAssetConfiguration.grantRole(
        keccak256("JOSEPH_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporAssetConfiguration.grantRole(
        keccak256("JOSEPH_ROLE"),
        accounts[0].address
    );

    await iporAssetConfiguration.grantRole(
        keccak256("REDEEM_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporAssetConfiguration.grantRole(
        keccak256("REDEEM_MAX_UTILIZATION_PERCENTAGE_ROLE"),
        accounts[0].address
    );

    await iporAssetConfiguration.grantRole(
        keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporAssetConfiguration.grantRole(
        keccak256("LP_MAX_UTILIZATION_PER_LEG_PERCENTAGE_ROLE"),
        accounts[0].address
    );
};
module.exports.grantAllRoleIporConfiguration = async (
    iporConfiguration,
    accounts
) => {
    await iporConfiguration.grantRole(
        keccak256("WARREN_STORAGE_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("WARREN_STORAGE_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("IPOR_ASSETS_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("IPOR_ASSETS_ROLE"),
        accounts[0].address
    );

    await iporConfiguration.grantRole(
        keccak256("WARREN_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("WARREN_ROLE"),
        accounts[0].address
    );

    await iporConfiguration.grantRole(
        keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
        accounts[0].address
    );

    await iporConfiguration.grantRole(
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE"),
        accounts[0].address
    );

    await iporConfiguration.grantRole(
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE"),
        accounts[0].address
    );

    await iporConfiguration.grantRole(
        keccak256("MILTON_SPREAD_MODEL_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("MILTON_SPREAD_MODEL_ROLE"),
        accounts[0].address
    );
};

module.exports.prepareApproveForUsers = async (
    users,
    asset,
    data,
    testData
) => {
    for (let i = 0; i < users.length; i++) {
        if (asset === "USDT") {
            await testData.tokenUsdt
                .connect(users[i])
                .approve(testData.josephUsdt.address, TOTAL_SUPPLY_6_DECIMALS);
            await testData.tokenUsdt
                .connect(users[i])
                .approve(testData.miltonUsdt.address, TOTAL_SUPPLY_6_DECIMALS);
        }
        if (asset === "USDC") {
            await testData.tokenUsdc
                .connect(users[i])
                .approve(testData.josephUsdc.address, TOTAL_SUPPLY_6_DECIMALS);
            await testData.tokenUsdc
                .connect(users[i])
                .approve(testData.miltonUsdc.address, TOTAL_SUPPLY_6_DECIMALS);
        }
        if (asset === "DAI") {
            await testData.tokenDai
                .connect(users[i])
                .approve(testData.josephDai.address, TOTAL_SUPPLY_18_DECIMALS);
            await testData.tokenDai
                .connect(users[i])
                .approve(testData.miltonDai.address, TOTAL_SUPPLY_18_DECIMALS);
        }
    }
};

module.exports.prepareData = async (libraries, accounts) => {
    const IporConfiguration = await ethers.getContractFactory(
        "IporConfiguration"
    );
    const iporConfiguration = await IporConfiguration.deploy();
    await iporConfiguration.deployed();
    await iporConfiguration.initialize();

    await this.grantAllRoleIporConfiguration(iporConfiguration, accounts);

    const MiltonDevToolDataProvider = await ethers.getContractFactory(
        "MiltonDevToolDataProvider"
    );
    const miltonDevToolDataProvider = await MiltonDevToolDataProvider.deploy(
        iporConfiguration.address
    );
    await miltonDevToolDataProvider.deployed();

    const MiltonFrontendDataProvider = await ethers.getContractFactory(
        "MiltonFrontendDataProvider"
    );
    const miltonFrontendDataProvider = await MiltonFrontendDataProvider.deploy(
        iporConfiguration.address
    );
    await miltonFrontendDataProvider.deployed();

    let miltonSpread = null;

    const MockMiltonSpreadModel = await ethers.getContractFactory(
        "MockMiltonSpreadModel"
    );

    miltonSpread = await MockMiltonSpreadModel.deploy();
    await miltonSpread.deployed();

    await iporConfiguration.setMiltonSpreadModel(miltonSpread.address);

    let data = {
        miltonSpread,
        iporConfiguration,
        miltonDevToolDataProvider,
        miltonFrontendDataProvider,
    };

    return data;
};

// TODO implement only for DAI
module.exports.prepareTestData = async (accounts, assets, data, lib) => {
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let ipTokenUsdt = null;
    let ipTokenUsdc = null;
    let ipTokenDai = null;
    let iporAssetConfigurationUsdt = null;
    let iporAssetConfigurationUsdc = null;
    let iporAssetConfigurationDai = null;
    let miltonUsdt = null;
    let miltonStorageUsdt = null;
    let josephUsdt = null;
    let miltonUsdc = null;
    let miltonStorageUsdc = null;
    let josephUsdc = null;
    let miltonDai = null;
    let miltonStorageDai = null;
    let josephDai = null;

    const IporAssetConfiguration = await ethers.getContractFactory(
        "IporAssetConfiguration"
    );
    const IpToken = await ethers.getContractFactory("IpToken");
    const UsdtMockedToken = await ethers.getContractFactory("UsdtMockedToken");
    const UsdcMockedToken = await ethers.getContractFactory("UsdcMockedToken");
    const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
    const ItfMilton = await ethers.getContractFactory("ItfMilton");
    const MiltonStorage = await ethers.getContractFactory("MiltonStorage");

    const ItfJoseph = await ethers.getContractFactory("ItfJoseph");

    const ItfWarren = await ethers.getContractFactory("ItfWarren");
    const warren = await ItfWarren.deploy(data.iporConfiguration.address);
    await warren.deployed();

    await warren.addUpdater(accounts[1].address);
    await data.iporConfiguration.setWarren(await warren.address);

    const MiltonLiquidityPoolUtilizationModel = await ethers.getContractFactory(
        "MiltonLiquidityPoolUtilizationModel"
    );
    const miltonLPUtilizationStrategyCollateral =
        await MiltonLiquidityPoolUtilizationModel.deploy();
    await miltonLPUtilizationStrategyCollateral.deployed();

    await data.iporConfiguration.setMiltonLiquidityPoolUtilizationModel(
        miltonLPUtilizationStrategyCollateral.address
    );

    for (let k = 0; k < assets.length; k++) {
        if (assets[k] === "USDT") {
            tokenUsdt = await UsdtMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            );
            await tokenUsdt.deployed();

            ipTokenUsdt = await IpToken.deploy(
                tokenUsdt.address,
                "IP USDT",
                "ipUSDT"
            );
            ipTokenUsdt.deployed();

            await data.iporConfiguration.addAsset(tokenUsdt.address);

            iporAssetConfigurationUsdt = await IporAssetConfiguration.deploy();
            await iporAssetConfigurationUsdt.deployed();
            await iporAssetConfigurationUsdt.initialize(
                tokenUsdt.address,
                ipTokenUsdt.address
            );

            await data.iporConfiguration.setIporAssetConfiguration(
                tokenUsdt.address,
                await iporAssetConfigurationUsdt.address
            );

            await this.grantAllRoleIporAssetConfiguration(
                iporAssetConfigurationUsdt,
                accounts
            );

            miltonStorageUsdt = await MiltonStorage.deploy();
            await miltonStorageUsdt.deployed();
            miltonStorageUsdt.initialize(
                tokenUsdt.address,
                data.iporConfiguration.address
            );

            await iporAssetConfigurationUsdt.setMiltonStorage(
                miltonStorageUsdt.address
            );

            miltonUsdt = await ItfMilton.deploy();
            await miltonUsdt.deployed();
            miltonUsdt.initialize(
                tokenUsdt.address,
                data.iporConfiguration.address
            );

            await iporAssetConfigurationUsdt.setMilton(miltonUsdt.address);

            josephUsdt = await ItfJoseph.deploy(
                tokenUsdt.address,
                ipTokenUsdt.address,
                miltonUsdt.address,
                miltonStorageUsdt.address
            );
            await josephUsdt.deployed();

            await ipTokenUsdt.setJoseph(josephUsdt.address);
            await iporAssetConfigurationUsdt.setJoseph(josephUsdt.address);

            await miltonUsdt.authorizeJoseph();
        }
        if (assets[k] === "USDC") {
            tokenUsdc = await UsdcMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            );
            tokenUsdc.deployed();

            await data.iporConfiguration.addAsset(tokenUsdc.address);

            ipTokenUsdc = await IpToken.deploy(
                tokenUsdc.address,
                "IP USDC",
                "ipUSDC"
            );
            ipTokenUsdc.deployed();

            iporAssetConfigurationUsdc = await IporAssetConfiguration.deploy();
            await iporAssetConfigurationUsdc.deployed();
            await iporAssetConfigurationUsdc.initialize(
                tokenUsdc.address,
                ipTokenUsdc.address
            );

            await data.iporConfiguration.setIporAssetConfiguration(
                tokenUsdc.address,
                await iporAssetConfigurationUsdc.address
            );

            miltonStorageUsdc = await MiltonStorage.deploy();
            await miltonStorageUsdc.deployed();
            miltonStorageUsdc.initialize(
                tokenUsdc.address,
                data.iporConfiguration.address
            );

            await this.grantAllRoleIporAssetConfiguration(
                iporAssetConfigurationUsdc,
                accounts
            );

            await iporAssetConfigurationUsdc.setMiltonStorage(
                miltonStorageUsdc.address
            );

            miltonUsdc = await ItfMilton.deploy();
            await miltonUsdc.deployed();
            miltonUsdc.initialize(
                tokenUsdc.address,
                data.iporConfiguration.address
            );
            await iporAssetConfigurationUsdc.setMilton(miltonUsdc.address);

            josephUsdc = await ItfJoseph.deploy(
                tokenUsdc.address,
                ipTokenUsdc.address,
                miltonUsdc.address,
                miltonStorageUsdc.address
            );
            await josephUsdc.deployed();

            await ipTokenUsdc.setJoseph(josephUsdc.address);
            await iporAssetConfigurationUsdc.setJoseph(josephUsdc.address);

            await miltonUsdc.authorizeJoseph();
        }
        if (assets[k] === "DAI") {
            tokenDai = await DaiMockedToken.deploy(
                TOTAL_SUPPLY_18_DECIMALS,
                18
            );
            await tokenDai.deployed();
            await data.iporConfiguration.addAsset(tokenDai.address);

            ipTokenDai = await IpToken.deploy(
                tokenDai.address,
                "IP DAI",
                "ipDAI"
            );
            await ipTokenDai.deployed();

            iporAssetConfigurationDai = await IporAssetConfiguration.deploy();
            await iporAssetConfigurationDai.deployed();
            await iporAssetConfigurationDai.initialize(
                tokenDai.address,
                ipTokenDai.address
            );

            await data.iporConfiguration.setIporAssetConfiguration(
                tokenDai.address,
                iporAssetConfigurationDai.address
            );

            miltonStorageDai = await MiltonStorage.deploy();
            await miltonStorageDai.deployed();
            miltonStorageDai.initialize(
                tokenDai.address,
                data.iporConfiguration.address
            );

            await this.grantAllRoleIporAssetConfiguration(
                iporAssetConfigurationDai,
                accounts
            );

            await iporAssetConfigurationDai.setMiltonStorage(
                miltonStorageDai.address
            );

            miltonDai = await ItfMilton.deploy();
            await miltonDai.deployed();
            miltonDai.initialize(
                tokenDai.address,
                data.iporConfiguration.address
            );
            await iporAssetConfigurationDai.setMilton(miltonDai.address);

            josephDai = await ItfJoseph.deploy(
                tokenDai.address,
                ipTokenDai.address,
                miltonDai.address,
                miltonStorageDai.address
            );
            await josephDai.deployed();
            await ipTokenDai.setJoseph(josephDai.address);
            await iporAssetConfigurationDai.setJoseph(josephDai.address);
            await miltonDai.authorizeJoseph();
        }
    }

    return {
        tokenDai,
        tokenUsdt,
        tokenUsdc,
        ipTokenUsdt,
        ipTokenUsdc,
        ipTokenDai,
        iporAssetConfigurationUsdt,
        iporAssetConfigurationUsdc,
        iporAssetConfigurationDai,
        warren,
        miltonUsdt,
        miltonStorageUsdt,
        josephUsdt,
        miltonUsdc,
        miltonStorageUsdc,
        josephUsdc,
        miltonDai,
        miltonStorageDai,
        josephDai,
    };
};

module.exports.grantAllSpreadRoles = async (data, admin, userOne) => {
    await data.miltonSpread.grantRole(
        keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE"),
        admin.address
    );
    const roleKf = keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE");
    await data.miltonSpread.grantRole(roleKf, userOne.address);

    await data.miltonSpread.grantRole(
        keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE"),
        admin.address
    );

    const roleLambda = keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE");
    await data.miltonSpread.grantRole(roleLambda, userOne.address);

    await data.miltonSpread.grantRole(
        keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE"),
        admin.address
    );

    const roleKOmega = keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE");
    await data.miltonSpread.grantRole(roleKOmega, userOne.address);

    await data.miltonSpread.grantRole(
        keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE"
        ),
        admin.address
    );
    const roleM = keccak256(
        "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE"
    );
    await data.miltonSpread.grantRole(roleM, userOne.address);

    await data.miltonSpread.grantRole(
        keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE"),
        admin.address
    );
    const roleKvol = keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE");
    await data.miltonSpread.grantRole(roleKvol, userOne.address);

    await data.miltonSpread.grantRole(
        keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE"),
        admin.address
    );
    const roleKHist = keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE");
    await data.miltonSpread.grantRole(roleKHist, userOne.address);

    await data.miltonSpread.grantRole(
        keccak256("SPREAD_MAX_VALUE_ADMIN_ROLE"),
        admin.address
    );
    const roleSpreadMax = keccak256("SPREAD_MAX_VALUE_ROLE");
    await data.miltonSpread.grantRole(roleSpreadMax, userOne.address);
};

module.exports.setupIpTokenDaiInitialValues = async (
    testData,
    liquidityProvider,
    initialAmount
) => {
    if (initialAmount > 0) {
        await testData.iporAssetConfigurationDai.setJoseph(
            liquidityProvider.address
        );
        await testData.ipTokenDai
            .connect(liquidityProvider)
            .mint(liquidityProvider.address, initialAmount);
        await testData.iporAssetConfigurationDai.setJoseph(
            testData.josephDai.address
        );
    }
};
module.exports.setupDefaultSpreadConstants = async (data, userOne) => {
    const spreadMaxValue = BigInt("10000000000000000");

    await data.miltonSpread.connect(userOne).setSpreadMaxValue(spreadMaxValue);

    await data.miltonSpread
        .connect(userOne)
        .setDemandComponentMaxLiquidityRedemptionValue(
            BigInt("1000000000000000000")
        );

    await data.miltonSpread
        .connect(userOne)
        .setDemandComponentLambdaValue(BigInt("0"));

    await data.miltonSpread
        .connect(userOne)
        .setDemandComponentKfValue(BigInt("1000000000000000"));

    await data.miltonSpread
        .connect(userOne)
        .setDemandComponentKOmegaValue(BigInt("30000000000000000"));

    await data.miltonSpread
        .connect(userOne)
        .setAtParComponentKVolValue(BigInt("31000000000000000"));

    await data.miltonSpread
        .connect(userOne)
        .setAtParComponentKHistValue(BigInt("14000000000000000"));
};

module.exports.setupIpTokenUsdtInitialValues = async (
    liquidityProvider,
    initialAmount
) => {
    if (initialAmount > 0) {
        await data.iporConfiguration.setJoseph(liquidityProvider.address);
        await data.ipTokenUsdt
            .connect(liquidityProvider)
            .mint(liquidityProvider, initialAmount);
        await data.iporConfiguration.setJoseph(data.joseph.address);
    }
};

module.exports.setupTokenDaiInitialValuesForUsers = async (users, testData) => {
    for (let i = 0; i < users.length; i++) {
        await testData.tokenDai.setupInitialAmount(
            users[i].address,
            USER_SUPPLY_10MLN_18DEC
        );
    }
};

module.exports.setupTokenUsdcInitialValuesForUsers = async (
    users,
    testData
) => {
    for (let i = 0; i < users.length; i++) {
        await testData.tokenUsdc.setupInitialAmount(
            users[i].address,
            USER_SUPPLY_6_DECIMALS
        );
    }
};

module.exports.setupTokenUsdtInitialValuesForUsers = async (
    users,
    testData
) => {
    for (let i = 0; i < users.length; i++) {
        await testData.tokenUsdt.setupInitialAmount(
            users[i].address,
            USER_SUPPLY_6_DECIMALS
        );
    }
};

module.exports.getPayFixedDerivativeParamsDAICase1 = (user, testData) => {
    return {
        asset: testData.tokenDai.address,
        totalAmount: USD_10_000_18DEC,
        slippageValue: 3,
        collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user,
    };
};

module.exports.getPayFixedDerivativeParamsUSDTCase1 = (user, testData) => {
    return {
        asset: testData.tokenUsdt.address,
        totalAmount: USD_10_000_6DEC,
        slippageValue: 3,
        collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user,
    };
};
