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
    const DerivativeLogic = await ethers.getContractFactory("DerivativeLogic");
    const derivativeLogic = await DerivativeLogic.deploy();
    await derivativeLogic.deployed();

    const DerivativesView = await ethers.getContractFactory("DerivativesView");
    const derivativesView = await DerivativesView.deploy();
    await derivativesView.deployed();

    const SoapIndicatorLogic = await ethers.getContractFactory(
        "SoapIndicatorLogic"
    );
    const soapIndicatorLogic = await SoapIndicatorLogic.deploy();
    await soapIndicatorLogic.deployed();

    return {
        derivativeLogic,
        derivativesView,
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
    await this.grantAllRoleIporConfiguration(iporConfiguration, accounts);

    const MiltonDevToolDataProvider = await ethers.getContractFactory(
        "MiltonDevToolDataProvider"
    );
    const miltonDevToolDataProvider = await MiltonDevToolDataProvider.deploy(
        iporConfiguration.address
    );
    await miltonDevToolDataProvider.deployed();

    const ItfWarren = await ethers.getContractFactory("ItfWarren");
    const warren = await ItfWarren.deploy(iporConfiguration.address);
    await warren.deployed();

    let miltonSpread = null;

    const MockMiltonSpreadModel = await ethers.getContractFactory(
        "MockMiltonSpreadModel"
    );

    miltonSpread = await MockMiltonSpreadModel.deploy(
        iporConfiguration.address
    );
    await miltonSpread.deployed();

    await iporConfiguration.setMiltonSpreadModel(miltonSpread.address);

    await iporConfiguration.setWarren(await warren.address);

    let data = {
        warren,
        miltonSpread,
        iporConfiguration,
        miltonDevToolDataProvider,
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
    const MiltonStorage = await ethers.getContractFactory("MiltonStorage", {
        libraries: {
            DerivativesView: lib.derivativesView.address,
        },
    });
    const WarrenStorage = await ethers.getContractFactory("WarrenStorage");
    const ItfJoseph = await ethers.getContractFactory("ItfJoseph");

    const warrenStorage = await WarrenStorage.deploy(
        data.iporConfiguration.address
    );
    await warrenStorage.deployed();

    await warrenStorage.addUpdater(accounts[1].address);
    await warrenStorage.addUpdater(data.warren.address);

    await data.iporConfiguration.setWarrenStorage(warrenStorage.address);

    const MiltonLPUtilizationStrategyCollateral =
        await ethers.getContractFactory(
            "MiltonLPUtilizationStrategyCollateral"
        );
    const miltonLPUtilizationStrategyCollateral =
        await MiltonLPUtilizationStrategyCollateral.deploy();
    await miltonLPUtilizationStrategyCollateral.deployed();

    await data.iporConfiguration.setMiltonLPUtilizationStrategy(
        miltonLPUtilizationStrategyCollateral.address
    );

    for (let k = 0; k < assets.length; k++) {
        if (assets[k] === "USDT") {
            tokenUsdt = await UsdtMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            );
            await tokenUsdt.deployed();
            await data.iporConfiguration.addAsset(tokenUsdt.address);

            ipTokenUsdt = await IpToken.deploy(
                tokenUsdt.address,
                "IP USDT",
                "ipUSDT"
            );
            ipTokenUsdt.deployed();

            iporAssetConfigurationUsdt = await IporAssetConfiguration.deploy(
                tokenUsdt.address,
                ipTokenUsdt.address
            );

            await iporAssetConfigurationUsdt.deployed();

            ipTokenUsdt.initialize(iporAssetConfigurationUsdt.address);

            await data.iporConfiguration.setIporAssetConfiguration(
                tokenUsdt.address,
                await iporAssetConfigurationUsdt.address
            );

            miltonStorageUsdt = await MiltonStorage.deploy(
                tokenUsdt.address,
                data.iporConfiguration.address
            );
            await miltonStorageUsdt.deployed();

            await this.grantAllRoleIporAssetConfiguration(
                iporAssetConfigurationUsdt,
                accounts
            );

            await iporAssetConfigurationUsdt.setMiltonStorage(
                miltonStorageUsdt.address
            );

            miltonUsdt = await ItfMilton.deploy(
                tokenUsdt.address,
                data.iporConfiguration.address
            );
            await miltonUsdt.deployed();
            await iporAssetConfigurationUsdt.setMilton(miltonUsdt.address);

            josephUsdt = await ItfJoseph.deploy(
                tokenUsdt.address,
                data.iporConfiguration.address
            );
            await josephUsdt.deployed();
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

            iporAssetConfigurationUsdc = await IporAssetConfiguration.deploy(
                tokenUsdc.address,
                ipTokenUsdc.address
            );
            iporAssetConfigurationUsdc.deployed();

            ipTokenUsdc.initialize(iporAssetConfigurationUsdc.address);

            await data.iporConfiguration.setIporAssetConfiguration(
                tokenUsdc.address,
                await iporAssetConfigurationUsdc.address
            );

            miltonStorageUsdc = await MiltonStorage.deploy(
                tokenUsdc.address,
                data.iporConfiguration.address
            );
            await miltonStorageUsdc.deployed();

            await this.grantAllRoleIporAssetConfiguration(
                iporAssetConfigurationUsdc,
                accounts
            );

            await iporAssetConfigurationUsdc.setMiltonStorage(
                miltonStorageUsdc.address
            );

            miltonUsdc = await ItfMilton.deploy(
                tokenUsdc.address,
                data.iporConfiguration.address
            );
            await miltonUsdc.deployed();
            await iporAssetConfigurationUsdc.setMilton(miltonUsdc.address);

            josephUsdc = await ItfJoseph.deploy(
                tokenUsdc.address,
                data.iporConfiguration.address
            );
            await josephUsdc.deployed();
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

            iporAssetConfigurationDai = await IporAssetConfiguration.deploy(
                tokenDai.address,
                ipTokenDai.address
            );
            await iporAssetConfigurationDai.deployed();

            ipTokenDai.initialize(iporAssetConfigurationDai.address);

            await data.iporConfiguration.setIporAssetConfiguration(
                tokenDai.address,
                iporAssetConfigurationDai.address
            );

            miltonStorageDai = await MiltonStorage.deploy(
                tokenDai.address,
                data.iporConfiguration.address
            );
            await miltonStorageDai.deployed();

            await this.grantAllRoleIporAssetConfiguration(
                iporAssetConfigurationDai,
                accounts
            );

            await iporAssetConfigurationDai.setMiltonStorage(
                miltonStorageDai.address
            );

            miltonDai = await ItfMilton.deploy(
                tokenDai.address,
                data.iporConfiguration.address
            );
            await miltonDai.deployed();
            await iporAssetConfigurationDai.setMilton(miltonDai.address);

            josephDai = await ItfJoseph.deploy(
                tokenDai.address,
                data.iporConfiguration.address
            );
            await josephDai.deployed();
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
        warrenStorage,
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
