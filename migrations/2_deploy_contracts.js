require("dotenv").config({ path: "../.env" });
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const keccak256 = require("keccak256");
const Issue = artifacts.require("Issue");
const MiltonFaucet = artifacts.require("MiltonFaucet");

const IporConfiguration = artifacts.require("IporConfiguration");

const IpToken = artifacts.require("IpToken");
const Warren = artifacts.require("Warren");
const ItfWarren = artifacts.require("ItfWarren");
const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
const MiltonLiquidityPoolUtilizationModel = artifacts.require(
    "MiltonLiquidityPoolUtilizationModel"
);

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");
const ItfMiltonDai = artifacts.require("ItfMiltonDai");
const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

const JosephUsdt = artifacts.require("JosephUsdt");
const JosephUsdc = artifacts.require("JosephUsdc");
const JosephDai = artifacts.require("JosephDai");
const ItfJosephUsdt = artifacts.require("ItfJosephUsdt");
const ItfJosephUsdc = artifacts.require("ItfJosephUsdc");
const ItfJosephDai = artifacts.require("ItfJosephDai");

const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");

const IporAssetConfigurationUsdt = artifacts.require(
    "IporAssetConfigurationUsdt"
);
const IporAssetConfigurationUsdc = artifacts.require(
    "IporAssetConfigurationUsdc"
);
const IporAssetConfigurationDai = artifacts.require(
    "IporAssetConfigurationDai"
);

const MiltonDevToolDataProvider = artifacts.require(
    "MiltonDevToolDataProvider"
);
const WarrenDevToolDataProvider = artifacts.require(
    "WarrenDevToolDataProvider"
);
const WarrenFrontendDataProvider = artifacts.require(
    "WarrenFrontendDataProvider"
);
const MiltonFrontendDataProvider = artifacts.require(
    "MiltonFrontendDataProvider"
);

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;

    await deployer.deploy(MiltonFaucet);
    const miltonFaucet = await MiltonFaucet.deployed();

    let stableTotalSupply6Decimals = "1000000000000000000";
    let stableTotalSupply18Decimals = "1000000000000000000000000000000";

    await deployer.deploy(UsdtMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdt = await UsdtMockedToken.deployed();

    await deployer.deploy(UsdcMockedToken, stableTotalSupply6Decimals, 6);
    const mockedUsdc = await UsdcMockedToken.deployed();

    await deployer.deploy(DaiMockedToken, stableTotalSupply18Decimals, 18);
    const mockedDai = await DaiMockedToken.deployed();

    await deployer.deploy(IpToken, mockedUsdt.address, "IP USDT", "ipUSDT");
    const ipUsdtToken = await IpToken.deployed();

    await deployer.deploy(IpToken, mockedUsdc.address, "IP USDC", "ipUSDC");
    const ipUsdcToken = await IpToken.deployed();

    await deployer.deploy(IpToken, mockedDai.address, "IP DAI", "ipDAI");
    const ipDaiToken = await IpToken.deployed();

    const iporAssetConfigurationUsdt = await deployProxy(
        IporAssetConfigurationUsdt,
        [mockedUsdt.address, ipUsdtToken.address]
		// ,
        // {
        //     initializer: "initialize",
        // }
    );

    // const iporAssetConfigurationUsdc = await deployProxy(
    //     IporAssetConfigurationUsdc,
    //     [mockedUsdc.address, ipUsdcToken.address],
    //     {
    //         deployer: deployer,
    //         initializer: "initialize",
    //     }
    // );

    // const iporAssetConfigurationDai = await deployProxy(
    //     IporAssetConfigurationDai,
    //     [mockedDai.address, ipDaiToken.address],
    //     {
    //         deployer: deployer,
    //         initializer: "initialize",
    //     }
    // );

    // const iporConfiguration = await deployProxy(IporConfiguration, {
    //     deployer: deployer,
    //     initializer: "initialize",
    // });

    // const miltonStorageUsdt = await deployProxy(
    //     MiltonStorage,
    //     [mockedUsdt.address, iporConfiguration.address],
    //     { deployer: deployer, initializer: "initialize" }
    // );

    //------------------------

    // await deployProxy(IporConfiguration, {
    //     deployer,
    //     unsafeAllow: "constructor",
    // });
    // iporConfiguration = await IporConfiguration.deployed();

    // // let warren = null;
    // // let miltonUsdt = null;
    // // let miltonUsdc = null;
    // // let miltonDai = null;
    // // let miltonStorageUsdt = null;
    // // let miltonStorageUsdc = null;
    // // let miltonStorageDai = null;

    // // let itfWarren = null;
    // // let itfMiltonUsdt = null;
    // // let itfMiltonUsdc = null;
    // // let itfMiltonDai = null;
    // // let josephUsdt = null;
    // // let josephUsdc = null;
    // // let josephDai = null;
    // // let itfJosephUsdt = null;
    // // let itfJosephUsdc = null;
    // // let itfJosephDai = null;
    // // let iporAssetConfigurationUsdt = null;
    // // let iporAssetConfigurationUsdc = null;
    // // let iporAssetConfigurationDai = null;

    // // let iporConfiguration = null;

    // // await deployProxy(Issue, { deployer });

    // await deployer.deploy(IporConfiguration);
    // iporConfiguration = await IporConfiguration.deployed();

    // await deployer.deploy(Warren, iporConfiguration.address);
    // warren = await Warren.deployed();

    // await deployer.deploy(
    //     MiltonFrontendDataProvider,
    //     iporConfiguration.address
    // );

    // await deployer.deploy(
    //     WarrenFrontendDataProvider,
    //     iporConfiguration.address
    // );

    // await deployer.deploy(
    //     MiltonLiquidityPoolUtilizationModel,
    //     iporConfiguration.address
    // );
    // let miltonLPUtilizationStrategyCollateral =
    //     await MiltonLiquidityPoolUtilizationModel.deployed();

    // await deployer.deploy(MiltonSpreadModel, iporConfiguration.address);
    // let miltonSpreadModel = await MiltonSpreadModel.deployed();

    // await deployer.deploy(UsdtMockedToken, totalSupply6Decimals, 6);
    // mockedUsdt = await UsdtMockedToken.deployed();
    // await iporConfiguration.addAsset(mockedUsdt.address);
    // await deployer.deploy(IpToken, mockedUsdt.address, "IP USDT", "ipUSDT");
    // ipUsdtToken = await IpToken.deployed();

    // await deployer.deploy(
    //     IporAssetConfigurationUsdt,
    //     mockedUsdt.address,
    //     ipUsdtToken.address
    // );
    // iporAssetConfigurationUsdt = await IporAssetConfigurationUsdt.deployed();

    // await ipUsdtToken.initialize(iporAssetConfigurationUsdt.address);

    // await deployer.deploy(
    //     MiltonStorageUsdt,
    //     mockedUsdt.address,
    //     iporConfiguration.address
    // );
    // miltonStorageUsdt = await MiltonStorageUsdt.deployed();

    // await deployer.deploy(UsdcMockedToken, totalSupply6Decimals, 6);
    // mockedUsdc = await UsdcMockedToken.deployed();
    // await iporConfiguration.addAsset(mockedUsdc.address);
    // await deployer.deploy(IpToken, mockedUsdc.address, "IP USDC", "ipUSDC");
    // ipUsdcToken = await IpToken.deployed();

    // await deployer.deploy(
    //     IporAssetConfigurationUsdc,
    //     mockedUsdc.address,
    //     ipUsdcToken.address
    // );

    // iporAssetConfigurationUsdc = await IporAssetConfigurationUsdc.deployed();

    // await ipUsdcToken.initialize(iporAssetConfigurationUsdc.address);

    // await iporConfiguration.setIporAssetConfiguration(
    //     mockedUsdc.address,
    //     await iporAssetConfigurationUsdc.address
    // );
    // await deployer.deploy(
    //     MiltonStorageUsdc,
    //     mockedUsdc.address,
    //     iporConfiguration.address
    // );
    // miltonStorageUsdc = await MiltonStorageUsdc.deployed();

    // await deployer.deploy(DaiMockedToken, totalSupply18Decimals, 18);
    // mockedDai = await DaiMockedToken.deployed();

    // await deployer.deploy(IpToken, mockedDai.address, "IP DAI", "ipDAI");
    // ipDaiToken = await IpToken.deployed();

    // await deployer.deploy(
    //     IporAssetConfigurationDai,
    //     mockedDai.address,
    //     ipDaiToken.address
    // );
    // iporAssetConfigurationDai = await IporAssetConfigurationDai.deployed();

    // await ipDaiToken.initialize(iporAssetConfigurationDai.address);

    // await deployer.deploy(
    //     MiltonStorageDai,
    //     mockedDai.address,
    //     iporConfiguration.address
    // );
    // miltonStorageDai = await MiltonStorageDai.deployed();

    // await deployer.deploy(WarrenDevToolDataProvider, iporConfiguration.address);
    // await deployer.deploy(MiltonDevToolDataProvider, iporConfiguration.address);

    // await deployer.deploy(
    //     MiltonUsdt,
    //     mockedUsdt.address,
    //     iporConfiguration.address
    // );
    // miltonUsdt = await MiltonUsdt.deployed();

    // await deployer.deploy(
    //     MiltonUsdc,
    //     mockedUsdc.address,
    //     iporConfiguration.address
    // );
    // miltonUsdc = await MiltonUsdc.deployed();

    // await deployer.deploy(
    //     MiltonDai,
    //     mockedDai.address,
    //     iporConfiguration.address
    // );
    // miltonDai = await MiltonDai.deployed();

    // await deployer.deploy(
    //     ItfMiltonUsdt,
    //     mockedUsdt.address,
    //     iporConfiguration.address
    // );
    // itfMiltonUsdt = await ItfMiltonUsdt.deployed();

    // await deployer.deploy(
    //     ItfMiltonUsdc,
    //     mockedUsdc.address,
    //     iporConfiguration.address
    // );
    // itfMiltonUsdc = await ItfMiltonUsdc.deployed();

    // await deployer.deploy(
    //     ItfMiltonDai,
    //     mockedDai.address,
    //     iporConfiguration.address
    // );
    // itfMiltonDai = await ItfMiltonDai.deployed();

    // await deployer.deploy(
    //     JosephUsdt,
    //     mockedUsdt.address,
    //     iporConfiguration.address
    // );
    // josephUsdt = await JosephUsdt.deployed();

    // await deployer.deploy(
    //     JosephUsdc,
    //     mockedUsdc.address,
    //     iporConfiguration.address
    // );
    // josephUsdc = await JosephUsdc.deployed();

    // await deployer.deploy(
    //     JosephDai,
    //     mockedDai.address,
    //     iporConfiguration.address
    // );
    // josephDai = await JosephDai.deployed();

    // await deployer.deploy(
    //     ItfJosephUsdt,
    //     mockedUsdt.address,
    //     iporConfiguration.address
    // );
    // itfJosephUsdt = await ItfJosephUsdt.deployed();

    // await deployer.deploy(
    //     ItfJosephUsdc,
    //     mockedUsdc.address,
    //     iporConfiguration.address
    // );
    // itfJosephUsdc = await ItfJosephUsdc.deployed();

    // await deployer.deploy(
    //     ItfJosephDai,
    //     mockedDai.address,
    //     iporConfiguration.address
    // );
    // itfJosephDai = await ItfJosephDai.deployed();
};
