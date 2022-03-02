// require("dotenv").config({ path: "../.env" });

const { deployProxy } = require("@openzeppelin/truffle-upgrades");
// const { artifacts } = require("hardhat");

// const keccak256 = require("keccak256");
const MiltonFaucet = artifacts.require("MiltonFaucet");
const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");
const IpTokenUsdt = artifacts.require("IpTokenUsdt");
const IpTokenUsdc = artifacts.require("IpTokenUsdc");
const IpTokenDai = artifacts.require("IpTokenDai");
const IporAssetConfigurationUsdt = artifacts.require(
    "IporAssetConfigurationUsdt"
);
const IporAssetConfigurationUsdc = artifacts.require(
    "IporAssetConfigurationUsdc"
);
const IporAssetConfigurationDai = artifacts.require(
    "IporAssetConfigurationDai"
);
const IporConfiguration = artifacts.require("IporConfiguration");
const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");
const Warren = artifacts.require("Warren");
const ItfWarren = artifacts.require("ItfWarren");
const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");
const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");
const ItfMiltonDai = artifacts.require("ItfMiltonDai");
const JosephUsdt = artifacts.require("JosephUsdt");
const JosephUsdc = artifacts.require("JosephUsdc");
const JosephDai = artifacts.require("JosephDai");
const ItfJosephUsdt = artifacts.require("ItfJosephUsdt");
const ItfJosephUsdc = artifacts.require("ItfJosephUsdc");
const ItfJosephDai = artifacts.require("ItfJosephDai");
const WarrenDevToolDataProvider = artifacts.require(
    "WarrenDevToolDataProvider"
);
const WarrenFrontendDataProvider = artifacts.require(
    "WarrenFrontendDataProvider"
);
const MiltonDevToolDataProvider = artifacts.require(
    "MiltonDevToolDataProvider"
);
const MiltonFrontendDataProvider = artifacts.require(
    "MiltonFrontendDataProvider"
);

const MockCaseBaseIporVault = artifacts.require("MockCaseBaseIporVault");

module.exports = async function (deployer, _network) {
    let stableTotalSupply6Decimals = "1000000000000000000";
    let stableTotalSupply18Decimals = "1000000000000000000000000000000";

    await deployer.deploy(MiltonFaucet);
    const miltonFaucet = await MiltonFaucet.deployed();

    await deployer.deploy(UsdtMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdt = await UsdtMockedToken.deployed();

    await deployer.deploy(UsdcMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdc = await UsdcMockedToken.deployed();

    await deployer.deploy(DaiMockedToken, stableTotalSupply18Decimals, 18);
    const mockedDai = await DaiMockedToken.deployed();

    await deployer.deploy(IpTokenUsdt, mockedUsdt.address, "IP USDT", "ipUSDT");
    const ipUsdtToken = await IpTokenUsdt.deployed();

    await deployer.deploy(IpTokenUsdc, mockedUsdc.address, "IP USDC", "ipUSDC");
    const ipUsdcToken = await IpTokenUsdc.deployed();

    await deployer.deploy(MockCaseBaseIporVault, mockedUsdt.address);
    const iporVaultUsdt = await MockCaseBaseIporVault.deployed();

    await deployer.deploy(MockCaseBaseIporVault, mockedUsdc.address);
    const iporVaultUsdc = await MockCaseBaseIporVault.deployed();

    await deployer.deploy(MockCaseBaseIporVault, mockedDai.address);
    const iporVaultDai = await MockCaseBaseIporVault.deployed();

    await deployer.deploy(IpTokenDai, mockedDai.address, "IP DAI", "ipDAI");
    const ipDaiToken = await IpTokenDai.deployed();

    const iporAssetConfigurationUsdt = await deployProxy(
        IporAssetConfigurationUsdt,
        [mockedUsdt.address, ipUsdtToken.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const iporAssetConfigurationUsdc = await deployProxy(
        IporAssetConfigurationUsdc,
        [mockedUsdc.address, ipUsdcToken.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const iporAssetConfigurationDai = await deployProxy(
        IporAssetConfigurationDai,
        [mockedDai.address, ipDaiToken.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonStorageUsdt = await deployProxy(MiltonStorageUsdt, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageUsdc = await deployProxy(MiltonStorageUsdc, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonStorageDai = await deployProxy(MiltonStorageDai, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const iporConfiguration = await deployProxy(IporConfiguration, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonSpreadModel = await deployProxy(MiltonSpreadModel, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const warren = await deployProxy(Warren, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const itfWarren = await deployProxy(ItfWarren, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const miltonUsdt = await deployProxy(
        MiltonUsdt,
        [
            mockedUsdt.address,
            ipUsdtToken.address,
            warren.address,
            miltonStorageUsdt.address,
            miltonSpreadModel.address,            
            iporVaultUsdt.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const itfMiltonUsdt = await deployProxy(
        ItfMiltonUsdt,
        [
            mockedUsdt.address,
            ipUsdtToken.address,
            itfWarren.address,
            miltonStorageUsdt.address,
            miltonSpreadModel.address,
            iporVaultUsdt.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonUsdc = await deployProxy(
        MiltonUsdc,
        [
            mockedUsdc.address,
            ipUsdcToken.address,
            warren.address,
            miltonStorageUsdc.address,
            miltonSpreadModel.address,
            iporVaultUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const itfMiltonUsdc = await deployProxy(
        ItfMiltonUsdc,
        [
            mockedUsdc.address,
            ipUsdcToken.address,
            itfWarren.address,
            miltonStorageUsdc.address,
            miltonSpreadModel.address,
            iporVaultUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonDai = await deployProxy(
        MiltonDai,
        [
            mockedDai.address,
            ipDaiToken.address,
            warren.address,
            miltonStorageDai.address,
            miltonSpreadModel.address,
            iporVaultDai.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const itfMiltonDai = await deployProxy(
        ItfMiltonDai,
        [
            mockedDai.address,
            ipDaiToken.address,
            itfWarren.address,
            miltonStorageDai.address,
            miltonSpreadModel.address,
            iporVaultDai.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephUsdt = await deployProxy(
        JosephUsdt,
        [
            mockedUsdt.address,
            ipUsdtToken.address,
            miltonUsdt.address,
            miltonStorageUsdt.address,
            iporVaultUsdt.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const itfJosephUsdt = await deployProxy(
        ItfJosephUsdt,
        [
            mockedUsdt.address,
            ipUsdtToken.address,
            itfMiltonUsdt.address,
            miltonStorageUsdt.address,
            iporVaultUsdt.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephUsdc = await deployProxy(
        JosephUsdc,
        [
            mockedUsdc.address,
            ipUsdcToken.address,
            miltonUsdc.address,
            miltonStorageUsdc.address,
            iporVaultUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const itfJosephUsdc = await deployProxy(
        ItfJosephUsdc,
        [
            mockedUsdc.address,
            ipUsdcToken.address,
            itfMiltonUsdc.address,
            miltonStorageUsdc.address,
            iporVaultUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephDai = await deployProxy(
        JosephDai,
        [
            mockedDai.address,
            ipDaiToken.address,
            miltonDai.address,
            miltonStorageDai.address,
            iporVaultDai.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const itfJosephDai = await deployProxy(
        ItfJosephDai,
        [
            mockedDai.address,
            ipDaiToken.address,
            itfMiltonDai.address,
            miltonStorageDai.address,
            iporVaultDai.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const warrenDevToolDataProvider = await deployProxy(
        WarrenDevToolDataProvider,
        [
            warren.address,
            mockedDai.address,
            mockedUsdc.address,
            mockedUsdt.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const warrenFrontendDataProvider = await deployProxy(
        WarrenFrontendDataProvider,
        [
            warren.address,
            mockedDai.address,
            mockedUsdt.address,
            mockedUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonDevToolDataProvider = await deployProxy(
        MiltonDevToolDataProvider,
        [iporConfiguration.address],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonFrontendDataProvider = await deployProxy(
        MiltonFrontendDataProvider,
        [
            iporConfiguration.address,
            warren.address,
            mockedDai.address,
            mockedUsdt.address,
            mockedUsdc.address,
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    console.log("Congratulations! DEPLOY Smart Contracts finished!");
};
