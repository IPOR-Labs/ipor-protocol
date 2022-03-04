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
        keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
        accounts[0].address
    );
    await iporConfiguration.grantRole(
        keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
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

module.exports.prepareData = async (accounts, spreadmiltonCaseNumber) => {
    const IporConfiguration = await ethers.getContractFactory(
        "IporConfiguration"
    );
    const iporConfiguration = await IporConfiguration.deploy();
    await iporConfiguration.deployed();
    await iporConfiguration.initialize();

    await this.grantAllRoleIporConfiguration(iporConfiguration, accounts);

    let MockCase1MiltonSpreadModel = null;

    if (spreadmiltonCaseNumber == 0) {
        MockCase1MiltonSpreadModel = await ethers.getContractFactory(
            "MockBaseMiltonSpreadModel"
        );
    } else {
        MockCase1MiltonSpreadModel = await ethers.getContractFactory(
            "MockCase" + spreadmiltonCaseNumber + "MiltonSpreadModel"
        );
    }

    const miltonSpread = await MockCase1MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();

    let data = {
        miltonSpread,
        iporConfiguration,
    };

    return data;
};

module.exports.prepareMiltonSpreadBase = async () => {
    const MockBaseMiltonSpreadModel = await ethers.getContractFactory(
        "MockBaseMiltonSpreadModel"
    );
    const miltonSpread = await MockBaseMiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};
module.exports.prepareMiltonSpreadCase2 = async () => {
    const MockCase2MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase2MiltonSpreadModel"
    );
    const miltonSpread = await MockCase2MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase3 = async () => {
    const MockCase3MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase3MiltonSpreadModel"
    );
    const miltonSpread = await MockCase3MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase4 = async () => {
    const MockCase4MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase4MiltonSpreadModel"
    );
    const miltonSpread = await MockCase4MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase5 = async () => {
    const MockCase5MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase5MiltonSpreadModel"
    );
    const miltonSpread = await MockCase5MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase6 = async () => {
    const MockCase6MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase6MiltonSpreadModel"
    );
    const miltonSpread = await MockCase6MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase7 = async () => {
    const MockCase7MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase7MiltonSpreadModel"
    );
    const miltonSpread = await MockCase7MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase8 = async () => {
    const MockCase8MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase8MiltonSpreadModel"
    );
    const miltonSpread = await MockCase8MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase9 = async () => {
    const MockCase9MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase9MiltonSpreadModel"
    );
    const miltonSpread = await MockCase9MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase10 = async () => {
    const MockCase10MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase10MiltonSpreadModel"
    );
    const miltonSpread = await MockCase10MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};

module.exports.prepareMiltonSpreadCase11 = async () => {
    const MockCase11MiltonSpreadModel = await ethers.getContractFactory(
        "MockCase11MiltonSpreadModel"
    );
    const miltonSpread = await MockCase11MiltonSpreadModel.deploy();
    await miltonSpread.deployed();
    await miltonSpread.initialize();
    return miltonSpread;
};
module.exports.getMockStanleyCase = async (stanleyCaseNumber, assetAddress) => {
    let MockCaseStanley = null;

    MockCaseStanley = await ethers.getContractFactory(
        "MockCase" + stanleyCaseNumber + "Stanley"
    );
    const mockCaseStanley = await MockCaseStanley.deploy(assetAddress);
    return mockCaseStanley;
};
module.exports.getMockMiltonCase = async (miltonCaseNumber) => {
    let MockCaseMilton = null;
    MockCaseMilton = await ethers.getContractFactory(
        "MockCase" + miltonCaseNumber + "Milton"
    );
    const mockCaseMilton = await MockCaseMilton.deploy();
    return mockCaseMilton;
};
module.exports.prepareWarren = async (accounts) => {
    const ItfWarren = await ethers.getContractFactory("ItfWarren");
    const warren = await ItfWarren.deploy();
    await warren.deployed();
    await warren.initialize();
    await warren.addUpdater(accounts[1].address);
    return warren;
};

module.exports.prepareComplexTestDataDaiCase40 = async (accounts, data) => {
    const testData = await this.prepareTestData(accounts, ["DAI"], data, 4, 0);
    await this.prepareApproveForUsers(accounts, "DAI", data, testData);
    await this.setupTokenDaiInitialValuesForUsers(accounts, testData);
    return testData;
};

module.exports.prepareComplexTestDataDaiCase00 = async (accounts, data) => {
    const testData = await this.prepareTestDataDaiCase1(accounts, data);
    await this.prepareApproveForUsers(accounts, "DAI", data, testData);
    await this.setupTokenDaiInitialValuesForUsers(accounts, testData);
    return testData;
};

module.exports.prepareComplexTestDataDaiCase01 = async (accounts, data) => {
    const testData = await this.prepareTestData(accounts, ["DAI"], data, 0, 1);
    await this.prepareApproveForUsers(accounts, "DAI", data, testData);
    await this.setupTokenDaiInitialValuesForUsers(accounts, testData);
    return testData;
};

module.exports.prepareTestDataDaiCase1 = async (accounts, data) => {
    return await this.prepareTestData(accounts, ["DAI"], data, 0, 0);
};
module.exports.prepareTestDataUsdtCase1 = async (accounts, data) => {
    return await this.prepareTestData(accounts, ["USDT"], data, 0, 0);
};

module.exports.prepareTestData = async (
    accounts,
    assets,
    data,
    miltonCaseNumber,
    stanleyCaseNumber
) => {
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
    let stanleyUsdt = null;
    let stanleyUsdc = null;
    let stanleyDai = null;

    const IporAssetConfiguration = await ethers.getContractFactory(
        "IporAssetConfiguration"
    );
    const IpToken = await ethers.getContractFactory("IpToken");
    const UsdtMockedToken = await ethers.getContractFactory("UsdtMockedToken");
    const UsdcMockedToken = await ethers.getContractFactory("UsdcMockedToken");
    const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
    const MiltonStorage = await ethers.getContractFactory("MiltonStorage");
    const ItfJoseph = await ethers.getContractFactory("ItfJoseph");

    const warren = await this.prepareWarren(accounts);

    for (let k = 0; k < assets.length; k++) {
        if (assets[k] === "USDT") {
            tokenUsdt = await UsdtMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            );
            await tokenUsdt.deployed();

            stanleyUsdt = await this.getMockStanleyCase(
                stanleyCaseNumber,
                tokenUsdt.address
            );

            ipTokenUsdt = await IpToken.deploy(
                tokenUsdt.address,
                "IP USDT",
                "ipUSDT"
            );
            await ipTokenUsdt.deployed();

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
            miltonStorageUsdt.initialize();

            await iporAssetConfigurationUsdt.setMiltonStorage(
                miltonStorageUsdt.address
            );

            miltonUsdt = await this.getMockMiltonCase(miltonCaseNumber);
            await miltonUsdt.deployed();
            miltonUsdt.initialize(
                tokenUsdt.address,
                ipTokenUsdt.address,
                warren.address,
                miltonStorageUsdt.address,
                data.miltonSpread.address,
                stanleyUsdt.address
            );

            await iporAssetConfigurationUsdt.setMilton(miltonUsdt.address);

            josephUsdt = await ItfJoseph.deploy();
            await josephUsdt.deployed();
            await josephUsdt.initialize(
                tokenUsdt.address,
                ipTokenUsdt.address,
                miltonUsdt.address,
                miltonStorageUsdt.address,
                stanleyUsdt.address
            );
            await miltonStorageUsdt.setJoseph(josephUsdt.address);
            await miltonStorageUsdt.setMilton(miltonUsdt.address);

            await ipTokenUsdt.setJoseph(josephUsdt.address);
            await iporAssetConfigurationUsdt.setJoseph(josephUsdt.address);

            await miltonUsdt.setJoseph(josephUsdt.address);
            await miltonUsdt.setupMaxAllowance(josephUsdt.address);
            await miltonUsdt.setupMaxAllowance(stanleyUsdt.address);
            // await stanleyUsdt.authorizeMilton(miltonUsdt.address);
            await warren.addAsset(tokenUsdt.address);
        }
        if (assets[k] === "USDC") {
            tokenUsdc = await UsdcMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            );
            await tokenUsdc.deployed();

            stanleyUsdc = await this.getMockStanleyCase(
                stanleyCaseNumber,
                tokenUsdc.address
            );

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
            miltonStorageUsdc.initialize();

            await this.grantAllRoleIporAssetConfiguration(
                iporAssetConfigurationUsdc,
                accounts
            );

            await iporAssetConfigurationUsdc.setMiltonStorage(
                miltonStorageUsdc.address
            );

            miltonUsdc = await this.getMockMiltonCase(miltonCaseNumber);
            await miltonUsdc.deployed();
            miltonUsdc.initialize(
                tokenUsdc.address,
                ipTokenUsdc.address,
                warren.address,
                miltonStorageUsdc.address,
                data.miltonSpread.address,
                stanleyUsdc.address
            );
            await iporAssetConfigurationUsdc.setMilton(miltonUsdc.address);

            josephUsdc = await ItfJoseph.deploy();
            await josephUsdc.deployed();
            await josephUsdc.initialize(
                tokenUsdc.address,
                ipTokenUsdc.address,
                miltonUsdc.address,
                miltonStorageUsdc.address,
                stanleyUsdc.address
            );

            await miltonStorageUsdc.setJoseph(josephUsdc.address);
            await miltonStorageUsdc.setMilton(miltonUsdc.address);

            await ipTokenUsdc.setJoseph(josephUsdc.address);
            await iporAssetConfigurationUsdc.setJoseph(josephUsdc.address);

            await miltonUsdc.setJoseph(josephUsdc.address);
            await miltonUsdc.setupMaxAllowance(josephUsdc.address);
            await miltonUsdc.setupMaxAllowance(stanleyUsdc.address);
            // await stanleyUsdc.authorizeMilton(miltonUsdc.address);
            await warren.addAsset(tokenUsdc.address);
        }
        if (assets[k] === "DAI") {
            tokenDai = await DaiMockedToken.deploy(
                TOTAL_SUPPLY_18_DECIMALS,
                18
            );
            await tokenDai.deployed();

            stanleyDai = await this.getMockStanleyCase(
                stanleyCaseNumber,
                tokenDai.address
            );

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
            miltonStorageDai.initialize();

            await this.grantAllRoleIporAssetConfiguration(
                iporAssetConfigurationDai,
                accounts
            );

            await iporAssetConfigurationDai.setMiltonStorage(
                miltonStorageDai.address
            );
            miltonDai = await this.getMockMiltonCase(miltonCaseNumber);
            await miltonDai.deployed();
            miltonDai.initialize(
                tokenDai.address,
                ipTokenDai.address,
                warren.address,
                miltonStorageDai.address,
                data.miltonSpread.address,
                stanleyDai.address
            );

            await iporAssetConfigurationDai.setMilton(miltonDai.address);

            josephDai = await ItfJoseph.deploy();
            await josephDai.deployed();
            await josephDai.initialize(
                tokenDai.address,
                ipTokenDai.address,
                miltonDai.address,
                miltonStorageDai.address,
                stanleyDai.address
            );

            await miltonStorageDai.setJoseph(josephDai.address);
            await miltonStorageDai.setMilton(miltonDai.address);

            await ipTokenDai.setJoseph(josephDai.address);
            await iporAssetConfigurationDai.setJoseph(josephDai.address);

            await miltonDai.setJoseph(josephDai.address);
            await miltonDai.setupMaxAllowance(josephDai.address);
            await miltonDai.setupMaxAllowance(stanleyDai.address);

            // await stanleyDai.authorizeMilton(miltonDai.address);

            await warren.addAsset(tokenDai.address);
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
        stanleyUsdt,
        stanleyUsdc,
        stanleyDai,
    };
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
