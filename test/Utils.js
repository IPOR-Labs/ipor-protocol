const keccak256 = require("keccak256");
const { expect } = require("chai");

const {
    COLLATERALIZATION_FACTOR_18DEC,
    TOTAL_SUPPLY_18_DECIMALS,
    TOTAL_SUPPLY_6_DECIMALS,
    USD_10_000_18DEC,
    USD_10_000_6DEC,
    USER_SUPPLY_18_DECIMALS,
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

    const TotalSoapIndicatorLogic = await ethers.getContractFactory(
        "TotalSoapIndicatorLogic"
    );
    const totalSoapIndicatorLogic = await TotalSoapIndicatorLogic.deploy();
    await totalSoapIndicatorLogic.deployed();

    return {
        derivativeLogic,
        derivativesView,
        totalSoapIndicatorLogic,
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
        collateralizationFactor: BigInt(10000000),
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user,
    };
};

module.exports.grantAllRoleIporConfiguration = async (
    iporConfiguration,
    accounts
) => {
    await iporConfiguration.grantRole(
        keccak256("MILTON_STORAGE_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("MILTON_STORAGE_ROLE"),
        accounts[0].address
    );
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
        keccak256("MILTON_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("MILTON_ROLE"),
        accounts[0].address
    );

    await iporConfiguration.grantRole(
        keccak256("JOSEPH_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("JOSEPH_ROLE"),
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
                .approve(data.joseph.address, TOTAL_SUPPLY_6_DECIMALS);
            await testData.tokenUsdt
                .connect(users[i])
                .approve(data.milton.address, TOTAL_SUPPLY_6_DECIMALS);
        }
        if (asset === "USDC") {
            await testData.tokenUsdc
                .connect(users[i])
                .approve(data.joseph.address, TOTAL_SUPPLY_6_DECIMALS);
            await testData.tokenUsdc
                .connect(users[i])
                .approve(data.milton.address, TOTAL_SUPPLY_6_DECIMALS);
        }
        if (asset === "DAI") {
            await testData.tokenDai
                .connect(users[i])
                .approve(data.joseph.address, TOTAL_SUPPLY_18_DECIMALS);
            await testData.tokenDai
                .connect(users[i])
                .approve(data.milton.address, TOTAL_SUPPLY_18_DECIMALS);
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

    const TestWarren = await ethers.getContractFactory("TestWarren");
    const warren = await TestWarren.deploy();
    await warren.deployed();

    const TestMilton = await ethers.getContractFactory("TestMilton");
    const milton = await TestMilton.deploy();
    await milton.deployed();

    const TestJoseph = await ethers.getContractFactory("TestJoseph");
    const joseph = await TestJoseph.deploy();
    await joseph.deployed();

    await iporConfiguration.setWarren(await warren.address);
    await iporConfiguration.setMilton(await milton.address);
    await iporConfiguration.setJoseph(await joseph.address);

    await warren.initialize(iporConfiguration.address);
    await milton.initialize(iporConfiguration.address);
    await joseph.initialize(iporConfiguration.address);

    let data = {
        warren,
        milton,
        joseph,
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
    let miltonSpread = null;    

    const MiltonStorage = await ethers.getContractFactory("MiltonStorage", {
        libraries: {
            DerivativesView: lib.derivativesView.address,
        },
    });
    const miltonStorage = await MiltonStorage.deploy();
    await miltonStorage.deployed();

    const WarrenStorage = await ethers.getContractFactory("WarrenStorage");
    const warrenStorage = await WarrenStorage.deploy();
    await warrenStorage.deployed();

    await warrenStorage.addUpdater(accounts[1].address);
    await warrenStorage.addUpdater(data.warren.address);

    await data.iporConfiguration.setMiltonStorage(miltonStorage.address);
    await data.iporConfiguration.setWarrenStorage(warrenStorage.address);

    await miltonStorage.initialize(data.iporConfiguration.address);
    await warrenStorage.initialize(data.iporConfiguration.address);

    const MiltonLPUtilizationStrategyCollateral =
        await ethers.getContractFactory(
            "MiltonLPUtilizationStrategyCollateral"
        );
    const miltonLPUtilizationStrategyCollateral =
        await MiltonLPUtilizationStrategyCollateral.deploy();
    await miltonLPUtilizationStrategyCollateral.deployed();
    await miltonLPUtilizationStrategyCollateral.initialize(
        data.iporConfiguration.address
    );
    await data.iporConfiguration.setMiltonLPUtilizationStrategy(
        miltonLPUtilizationStrategyCollateral.address
    );

    const MockMiltonSpreadModel = await ethers.getContractFactory(
        "MockMiltonSpreadModel"
    );

	miltonSpread = await MockMiltonSpreadModel.deploy(		
		data.iporConfiguration.address
	);
	await miltonSpread.deployed();

    for (let k = 0; k < assets.length; k++) {
        if (assets[k] === "USDT") {
            const UsdtMockedToken = await ethers.getContractFactory(
                "UsdtMockedToken"
            );
            tokenUsdt = await UsdtMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            );
            await tokenUsdt.deployed();
            await data.iporConfiguration.addAsset(tokenUsdt.address);
            await data.milton.authorizeJoseph(tokenUsdt.address);
            const IpToken = await ethers.getContractFactory("IpToken");
            ipTokenUsdt = await IpToken.deploy(
                tokenUsdt.address,
                "IP USDT",
                "ipUSDT"
            );
            ipTokenUsdt.deployed();
            ipTokenUsdt.initialize(data.iporConfiguration.address);
            const IporAssetConfigurationUsdt = await ethers.getContractFactory(
                "IporAssetConfiguration"
            );
            iporAssetConfigurationUsdt =
                await IporAssetConfigurationUsdt.deploy(
                    tokenUsdt.address,
                    ipTokenUsdt.address
                );
            await iporAssetConfigurationUsdt.deployed();
            await data.iporConfiguration.setIporAssetConfiguration(
                tokenUsdt.address,
                await iporAssetConfigurationUsdt.address
            );
            await miltonStorage.addAsset(tokenUsdt.address);           
        }
        if (assets[k] === "USDC") {
            const UsdcMockedToken = await ethers.getContractFactory(
                "UsdcMockedToken"
            );
            tokenUsdc = await UsdcMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            );
            tokenUsdc.deployed();

            await data.iporConfiguration.addAsset(tokenUsdc.address);
            await data.milton.authorizeJoseph(tokenUsdc.address);

            const IpToken = await ethers.getContractFactory("IpToken");
            ipTokenUsdc = await IpToken.deploy(
                tokenUsdc.address,
                "IP USDC",
                "ipUSDC"
            );
            ipTokenUsdc.deployed();
            ipTokenUsdc.initialize(data.iporConfiguration.address);

            const IporAssetConfigurationUsdc = await ethers.getContractFactory(
                "IporAssetConfiguration"
            );
            iporAssetConfigurationUsdc =
                await IporAssetConfigurationUsdc.deploy(
                    tokenUsdc.address,
                    ipTokenUsdc.address
                );
            iporAssetConfigurationUsdc.deployed();
            await data.iporConfiguration.setIporAssetConfiguration(
                tokenUsdc.address,
                await iporAssetConfigurationUsdc.address
            );
            await miltonStorage.addAsset(tokenUsdc.address);

        }
        if (assets[k] === "DAI") {
            const DaiMockedToken = await ethers.getContractFactory(
                "DaiMockedToken"
            );
            tokenDai = await DaiMockedToken.deploy(
                TOTAL_SUPPLY_18_DECIMALS,
                18
            );
            await tokenDai.deployed();
            await data.iporConfiguration.addAsset(tokenDai.address);
            await data.milton.authorizeJoseph(tokenDai.address);

            const IpToken = await ethers.getContractFactory("IpToken");
            ipTokenDai = await IpToken.deploy(
                tokenDai.address,
                "IP DAI",
                "ipDAI"
            );
            await ipTokenDai.deployed();
            ipTokenDai.initialize(data.iporConfiguration.address);

            const IporAssetConfigurationDai = await ethers.getContractFactory(
                "IporAssetConfiguration"
            );
            iporAssetConfigurationDai = await IporAssetConfigurationDai.deploy(
                tokenDai.address,
                ipTokenDai.address
            );
            await iporAssetConfigurationDai.deployed();

            await data.iporConfiguration.setIporAssetConfiguration(
                tokenDai.address,
                iporAssetConfigurationDai.address
            );
            await miltonStorage.addAsset(tokenDai.address);

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
        miltonStorage,        
        miltonSpread,
        warrenStorage,
    };
};

module.exports.grantAllSpreadRolesForDAI = async (testData, admin, userOne) => {
    await testData.miltonSpread.grantRole(
        keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE"),
        admin.address
    );
    const roleKf = keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE");
    await testData.miltonSpread.grantRole(roleKf, userOne.address);

    await testData.miltonSpread.grantRole(
        keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE"),
        admin.address
    );

    const roleLambda = keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE");
    await testData.miltonSpread.grantRole(roleLambda, userOne.address);

    await testData.miltonSpread.grantRole(
        keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE"),
        admin.address
    );

    const roleKOmega = keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE");
    await testData.miltonSpread.grantRole(roleKOmega, userOne.address);

    await testData.miltonSpread.grantRole(
        keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE"
        ),
        admin.address
    );
    const roleM = keccak256(
        "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE"
    );
    await testData.miltonSpread.grantRole(roleM, userOne.address);

    await testData.miltonSpread.grantRole(
        keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE"),
        admin.address
    );
    const roleKvol = keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE");
    await testData.miltonSpread.grantRole(roleKvol, userOne.address);

    await testData.miltonSpread.grantRole(
        keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE"),
        admin.address
    );
    const roleKHist = keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE");
    await testData.miltonSpread.grantRole(roleKHist, userOne.address);

    await testData.miltonSpread.grantRole(
        keccak256("SPREAD_MAX_VALUE_ADMIN_ROLE"),
        admin.address
    );
    const roleSpreadMax = keccak256("SPREAD_MAX_VALUE_ROLE");
    await testData.miltonSpread.grantRole(roleSpreadMax, userOne.address);
};

module.exports.setupIpTokenDaiInitialValues = async (
    liquidityProvider,
    initialAmount
) => {
    if (initialAmount > 0) {
        await data.iporConfiguration.setJoseph(liquidityProvider.address);
        await data.ipTokenDai
            .connect(liquidityProvider)
            .mint(liquidityProvider.address, initialAmount);
        await data.iporConfiguration.setJoseph(data.joseph.address);
    }
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
            USER_SUPPLY_18_DECIMALS
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
        collateralizationFactor: BigInt(10000000),
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user,
    };
};
