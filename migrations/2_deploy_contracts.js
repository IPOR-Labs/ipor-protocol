require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const Warren = artifacts.require("Warren");
const WarrenStorage = artifacts.require("WarrenStorage");
const Milton = artifacts.require("Milton");
const MiltonStorage = artifacts.require("MiltonStorage");
const MiltonFaucet = artifacts.require("MiltonFaucet");
const TestWarren = artifacts.require("TestWarren");
const TestMilton = artifacts.require("TestMilton");
const TestJoseph = artifacts.require("TestJoseph");
const IpToken = artifacts.require("IpToken");
const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");
const IporLogic = artifacts.require("IporLogic");
const DerivativeLogic = artifacts.require("DerivativeLogic");
const SoapIndicatorLogic = artifacts.require("SoapIndicatorLogic");
const TotalSoapIndicatorLogic = artifacts.require("TotalSoapIndicatorLogic");
const DerivativesView = artifacts.require("DerivativesView");
const IporAssetConfigurationUsdt = artifacts.require(
    "IporAssetConfigurationUsdt"
);
const IporAssetConfigurationUsdc = artifacts.require(
    "IporAssetConfigurationUsdc"
);
const IporAssetConfigurationDai = artifacts.require(
    "IporAssetConfigurationDai"
);
const AmmMath = artifacts.require("AmmMath");
const IporConfiguration = artifacts.require("IporConfiguration");
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
const MiltonLPUtilizationStrategyCollateral = artifacts.require(
    "MiltonLPUtilizationStrategyCollateral"
);
const MiltonSpreadStrategy = artifacts.require("MiltonSpreadStrategy");
const Joseph = artifacts.require("Joseph");

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;

    let isTestEnvironment = 1;

    if (_network === "mainnet") {
        isTestEnvironment = 0;
    }

    let faucetSupply6Decimals = "10000000000000000";
    let faucetSupply18Decimals = "10000000000000000000000000000";

    let totalSupply6Decimals = "1000000000000000000";
    let totalSupply18Decimals = "1000000000000000000000000000000";

    let userSupply6Decimals = "1000000000000";
    let userSupply18Decimals = "1000000000000000000000000";

    let ipUsdtToken = null;
    let ipUsdcToken = null;
    let ipDaiToken = null;

    let mockedUsdt = null;
    let mockedUsdc = null;
    let mockedDai = null;
    let milton = null;
    let testMilton = null;
    let joseph = null;
    let testJoseph = null;
    let miltonStorage = null;
    let miltonFaucet = null;
    let iporAssetConfigurationUsdt = null;
    let iporAssetConfigurationUsdc = null;
    let iporAssetConfigurationDai = null;
    let iporConfiguration = null;

    await deployer.deploy(AmmMath);

    // await deployer.link(AmmMath, IporLogic);
    // await deployer.link(AmmMath, Warren);
    // await deployer.link(AmmMath, IporAssetConfigurationUsdt);
    // await deployer.link(AmmMath, IporAssetConfigurationUsdc);
    // await deployer.link(AmmMath, IporAssetConfigurationDai);
    // await deployer.link(AmmMath, DerivativeLogic);
    // await deployer.link(AmmMath, SoapIndicatorLogic);
    // await deployer.link(AmmMath, MiltonStorage);

    await deployer.deploy(IporLogic);

    await deployer.link(IporLogic, Warren);
    await deployer.link(IporLogic, WarrenStorage);

    await deployer.deploy(WarrenStorage);
    let warrenStorage = await WarrenStorage.deployed();

    await deployer.deploy(Warren);
    let warren = await Warren.deployed();

    await deployer.deploy(DerivativeLogic);

    await deployer.deploy(SoapIndicatorLogic);

    await deployer.link(SoapIndicatorLogic, TotalSoapIndicatorLogic);
    await deployer.deploy(TotalSoapIndicatorLogic);

    await deployer.deploy(DerivativesView);

    await deployer.link(SoapIndicatorLogic, MiltonStorage);
    await deployer.link(DerivativeLogic, MiltonStorage);
    await deployer.link(TotalSoapIndicatorLogic, MiltonStorage);
    await deployer.link(DerivativesView, MiltonStorage);
    await deployer.link(DerivativeLogic, Milton);

    const IPOR_ASSETS_ADMIN_ROLE = keccak256("IPOR_ASSETS_ADMIN_ROLE");
    const MILTON_ADMIN_ROLE = keccak256("MILTON_ADMIN_ROLE");
    const MILTON_STORAGE_ADMIN_ROLE = keccak256("MILTON_STORAGE_ADMIN_ROLE");
    const MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE = keccak256(
        "MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE"
    );
    const MILTON_SPREAD_STRATEGY_ADMIN_ROLE = keccak256(
        "MILTON_SPREAD_STRATEGY_ADMIN_ROLE"
    );
    const IPOR_ASSET_CONFIGURATION_ADMIN_ROLE = keccak256(
        "IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"
    );
    const WARREN_ADMIN_ROLE = keccak256("WARREN_ADMIN_ROLE");
    const WARREN_STORAGE_ADMIN_ROLE = keccak256("WARREN_STORAGE_ADMIN_ROLE");
    const JOSEPH_ADMIN_ROLE = keccak256("JOSEPH_ADMIN_ROLE");
    const MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE = keccak256(
        "MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"
    );
    const ROLES_INFO_ADMIN_ROLE = keccak256("ROLES_INFO_ADMIN_ROLE");

    const IPOR_ASSETS_ROLE = keccak256("IPOR_ASSETS_ROLE");
    const MILTON_ROLE = keccak256("MILTON_ROLE");
    const MILTON_STORAGE_ROLE = keccak256("MILTON_STORAGE_ROLE");
    const MILTON_LP_UTILIZATION_STRATEGY_ROLE = keccak256(
        "MILTON_LP_UTILIZATION_STRATEGY_ROLE"
    );
    const MILTON_SPREAD_STRATEGY_ROLE = keccak256(
        "MILTON_SPREAD_STRATEGY_ROLE"
    );
    const IPOR_ASSET_CONFIGURATION_ROLE = keccak256(
        "IPOR_ASSET_CONFIGURATION_ROLE"
    );
    const WARREN_ROLE = keccak256("WARREN_ROLE");
    const WARREN_STORAGE_ROLE = keccak256("WARREN_STORAGE_ROLE");
    const JOSEPH_ROLE = keccak256("JOSEPH_ROLE");
    const MILTON_PUBLICATION_FEE_TRANSFERER_ROLE = keccak256(
        "MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"
    );
    const ROLES_INFO_ROLE = keccak256("ROLES_INFO_ROLE");

    await deployer.deploy(IporConfiguration);
    iporConfiguration = await IporConfiguration.deployed();

    await iporConfiguration.grantRole(ROLES_INFO_ADMIN_ROLE, admin);
    await iporConfiguration.grantRole(ROLES_INFO_ROLE, admin);

    await iporConfiguration.grantRole(IPOR_ASSETS_ADMIN_ROLE, admin);
    await iporConfiguration.grantRole(IPOR_ASSETS_ROLE, admin);

    await iporConfiguration.grantRole(MILTON_ADMIN_ROLE, admin);
    await iporConfiguration.grantRole(MILTON_ROLE, admin);

    await iporConfiguration.grantRole(MILTON_STORAGE_ADMIN_ROLE, admin);
    await iporConfiguration.grantRole(MILTON_STORAGE_ROLE, admin);

    await iporConfiguration.grantRole(
        MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE,
        admin
    );
    await iporConfiguration.grantRole(
        MILTON_LP_UTILIZATION_STRATEGY_ROLE,
        admin
    );

    await iporConfiguration.grantRole(MILTON_SPREAD_STRATEGY_ADMIN_ROLE, admin);
    await iporConfiguration.grantRole(MILTON_SPREAD_STRATEGY_ROLE, admin);

    await iporConfiguration.grantRole(
        IPOR_ASSET_CONFIGURATION_ADMIN_ROLE,
        admin
    );
    await iporConfiguration.grantRole(IPOR_ASSET_CONFIGURATION_ROLE, admin);

    await iporConfiguration.grantRole(WARREN_ADMIN_ROLE, admin);
    await iporConfiguration.grantRole(WARREN_ROLE, admin);

    await iporConfiguration.grantRole(WARREN_STORAGE_ADMIN_ROLE, admin);
    await iporConfiguration.grantRole(WARREN_STORAGE_ROLE, admin);

    await iporConfiguration.grantRole(JOSEPH_ADMIN_ROLE, admin);
    await iporConfiguration.grantRole(JOSEPH_ROLE, admin);

    await iporConfiguration.grantRole(
        MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE,
        admin
    );
    await iporConfiguration.grantRole(
        MILTON_PUBLICATION_FEE_TRANSFERER_ROLE,
        admin
    );

    await deployer.deploy(
        MiltonFrontendDataProvider,
        iporConfiguration.address
    );

    // await deployer.link(AmmMath, WarrenFrontendDataProvider);
    await deployer.deploy(
        WarrenFrontendDataProvider,
        iporConfiguration.address
    );

    // await deployer.link(AmmMath, MiltonLPUtilizationStrategyCollateral);
    await deployer.deploy(MiltonLPUtilizationStrategyCollateral);
    let miltonLPUtilizationStrategyCollateral =
        await MiltonLPUtilizationStrategyCollateral.deployed();
    await iporConfiguration.grantRole(
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE"),
        admin
    );
    await iporConfiguration.setMiltonLPUtilizationStrategy(
        miltonLPUtilizationStrategyCollateral.address
    );

    await deployer.deploy(MiltonSpreadStrategy);
    let miltonSpreadStrategy = await MiltonSpreadStrategy.deployed();
    await iporConfiguration.grantRole(
        keccak256("MILTON_SPREAD_STRATEGY_ROLE"),
        admin
    );
    await iporConfiguration.setMiltonSpreadStrategy(
        miltonSpreadStrategy.address
    );

    // prepare ERC20 mocked tokens...
    if (
        _network === "develop" ||
        _network === "develop2" ||
        _network === "dev" ||
        _network === "docker" ||
        _network === "soliditycoverage"
    ) {
        await deployer.deploy(UsdtMockedToken, totalSupply6Decimals, 6);
        mockedUsdt = await UsdtMockedToken.deployed();

        await deployer.deploy(UsdcMockedToken, totalSupply6Decimals, 6);
        mockedUsdc = await UsdcMockedToken.deployed();

        await deployer.deploy(DaiMockedToken, totalSupply18Decimals, 18);
        mockedDai = await DaiMockedToken.deployed();

        await deployer.deploy(MiltonFaucet);

        miltonFaucet = await MiltonFaucet.deployed();

        if (_network === "soliditycoverage") {
            miltonFaucet.sendTransaction({
                from: admin,
                value: "50000000000000000000",
            });
        } else {
            miltonFaucet.sendTransaction({
                from: admin,
                value: "500000000000000000000000",
            });
        }

        await deployer.deploy(
            MiltonDevToolDataProvider,
            iporConfiguration.address
        );

        // await deployer.link(AmmMath, WarrenDevToolDataProvider);
        await deployer.deploy(
            WarrenDevToolDataProvider,
            iporConfiguration.address
        );

        await deployer.deploy(IpToken, mockedUsdt.address, "IP USDT", "ipUSDT");
        ipUsdtToken = await IpToken.deployed();
        await deployer.deploy(IpToken, mockedUsdc.address, "IP USDC", "ipUSDC");
        ipUsdcToken = await IpToken.deployed();
        await deployer.deploy(IpToken, mockedDai.address, "IP DAI", "ipDAI");
        ipDaiToken = await IpToken.deployed();

        await deployer.deploy(
            IporAssetConfigurationUsdt,
            mockedUsdt.address,
            ipUsdtToken.address
        );
        iporAssetConfigurationUsdt =
            await IporAssetConfigurationUsdt.deployed();

        await deployer.deploy(
            IporAssetConfigurationUsdc,
            mockedUsdc.address,
            ipUsdcToken.address
        );
        iporAssetConfigurationUsdc =
            await IporAssetConfigurationUsdc.deployed();

        await deployer.deploy(
            IporAssetConfigurationDai,
            mockedDai.address,
            ipDaiToken.address
        );
        iporAssetConfigurationDai = await IporAssetConfigurationDai.deployed();
        await iporConfiguration.addAsset(mockedDai.address);
        await iporConfiguration.addAsset(mockedUsdt.address);
        await iporConfiguration.addAsset(mockedUsdc.address);

        await iporConfiguration.setIporAssetConfiguration(
            mockedUsdt.address,
            await iporAssetConfigurationUsdt.address
        );
        await iporConfiguration.setIporAssetConfiguration(
            mockedUsdc.address,
            await iporAssetConfigurationUsdc.address
        );
        await iporConfiguration.setIporAssetConfiguration(
            mockedDai.address,
            await iporAssetConfigurationDai.address
        );

        await ipUsdtToken.initialize(iporConfiguration.address);
        await ipUsdcToken.initialize(iporConfiguration.address);
        await ipDaiToken.initialize(iporConfiguration.address);
    } else {
        if (_network !== "test") {
            //only public network - test and production
            console.log("NETWORK: " + _network);
            await iporConfiguration.addAsset(
                process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS
            );
            await iporConfiguration.addAsset(
                process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS
            );
            await iporConfiguration.addAsset(
                process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS
            );
            await miltonStorage.addAsset(
                process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS
            );
            await miltonStorage.addAsset(
                process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS
            );
            await miltonStorage.addAsset(
                process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS
            );

            await deployer.deploy(
                IpToken,
                process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS,
                "IP USDT",
                "ipUSDT"
            );
            ipUsdtToken = await IpToken.deployed();
            await deployer.deploy(
                IpToken,
                process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS,
                "IP USDC",
                "ipUSDC"
            );
            ipUsdcToken = await IpToken.deployed();
            await deployer.deploy(
                IpToken,
                process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS,
                "IP DAI",
                "ipDAI"
            );
            ipDaiToken = await IpToken.deployed();

            const INCOME_TAX_PERCENTAGE_ADMIN_ROLE = keccak256(
                "INCOME_TAX_PERCENTAGE_ADMIN_ROLE"
            );
            const OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE = keccak256(
                "OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"
            );
            const LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE = keccak256(
                "LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE"
            );
            const OPENING_FEE_PERCENTAGE_ADMIN_ROLE = keccak256(
                "OPENING_FEE_PERCENTAGE_ADMIN_ROLE"
            );
            const IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE = keccak256(
                "IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE"
            );
            const LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE =
                keccak256(
                    "LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"
                );
            const MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE = keccak256(
                "MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE"
            );
            const SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE = keccak256(
                "SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE"
            );
            const SPREAD_REC_FIXED_VALUE_ADMIN_ROLE = keccak256(
                "SPREAD_REC_FIXED_VALUE_ADMIN_ROLE"
            );
            const COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE = keccak256(
                "COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE"
            );
            const CHARLIE_TREASURER_ADMIN_ROLE = keccak256(
                "CHARLIE_TREASURER_ADMIN_ROLE"
            );
            const TREASURE_TREASURER_ADMIN_ROLE = keccak256(
                "TREASURE_TREASURER_ADMIN_ROLE"
            );
            const ASSET_MANAGEMENT_VAULT_ADMIN_ROLE = keccak256(
                "ASSET_MANAGEMENT_VAULT_ADMIN_ROLE"
            );
            const DECAY_FACTOR_VALUE_ADMIN_ROLE = keccak256(
                "DECAY_FACTOR_VALUE_ADMIN_ROLE"
            );

            const INCOME_TAX_PERCENTAGE_ROLE = keccak256(
                "INCOME_TAX_PERCENTAGE_ROLE"
            );
            const OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE = keccak256(
                "OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"
            );
            const LIQUIDATION_DEPOSIT_AMOUNT_ROLE = keccak256(
                "LIQUIDATION_DEPOSIT_AMOUNT_ROLE"
            );
            const OPENING_FEE_PERCENTAGE_ROLE = keccak256(
                "OPENING_FEE_PERCENTAGE_ROLE"
            );
            const IPOR_PUBLICATION_FEE_AMOUNT_ROLE = keccak256(
                "IPOR_PUBLICATION_FEE_AMOUNT_ROLE"
            );
            const LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE = keccak256(
                "LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"
            );
            const MAX_POSITION_TOTAL_AMOUNT_ROLE = keccak256(
                "MAX_POSITION_TOTAL_AMOUNT_ROLE"
            );
            const SPREAD_PAY_FIXED_VALUE_ROLE = keccak256(
                "SPREAD_PAY_FIXED_VALUE_ROLE"
            );
            const SPREAD_REC_FIXED_VALUE_ROLE = keccak256(
                "SPREAD_REC_FIXED_VALUE_ROLE"
            );
            const COLLATERALIZATION_FACTOR_VALUE_ROLE = keccak256(
                "COLLATERALIZATION_FACTOR_VALUE_ROLE"
            );
            const CHARLIE_TREASURER_ROLE = keccak256("CHARLIE_TREASURER_ROLE");
            const TREASURE_TREASURER_ROLE = keccak256(
                "TREASURE_TREASURER_ROLE"
            );
            const ASSET_MANAGEMENT_VAULT_ROLE = keccak256(
                "ASSET_MANAGEMENT_VAULT_ROLE"
            );
            const DECAY_FACTOR_VALUE_ROLE = keccak256(
                "DECAY_FACTOR_VALUE_ROLE"
            );

            await deployer.deploy(
                IporAssetConfiguration,
                process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS,
                ipUsdtToken.address
            );
            iporAssetConfigurationUsdt =
                await IporAssetConfiguration.deployed();
            await iporAssetConfigurationUsdt.grantRole(
                INCOME_TAX_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                INCOME_TAX_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                LIQUIDATION_DEPOSIT_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                OPENING_FEE_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                OPENING_FEE_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                IPOR_PUBLICATION_FEE_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                MAX_POSITION_TOTAL_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                SPREAD_PAY_FIXED_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                SPREAD_REC_FIXED_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                SPREAD_REC_FIXED_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                COLLATERALIZATION_FACTOR_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                CHARLIE_TREASURER_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                CHARLIE_TREASURER_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                TREASURE_TREASURER_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                TREASURE_TREASURER_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                ASSET_MANAGEMENT_VAULT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                ASSET_MANAGEMENT_VAULT_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                DECAY_FACTOR_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdt.grantRole(
                DECAY_FACTOR_VALUE_ROLE,
                admin
            );

            await deployer.deploy(
                IporAssetConfiguration,
                process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS,
                ipUsdcToken.address
            );
            iporAssetConfigurationUsdc =
                await IporAssetConfiguration.deployed();
            await iporAssetConfigurationUsdc.grantRole(
                INCOME_TAX_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                INCOME_TAX_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                LIQUIDATION_DEPOSIT_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                OPENING_FEE_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                OPENING_FEE_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                IPOR_PUBLICATION_FEE_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                MAX_POSITION_TOTAL_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                SPREAD_PAY_FIXED_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                SPREAD_REC_FIXED_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                SPREAD_REC_FIXED_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                COLLATERALIZATION_FACTOR_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                CHARLIE_TREASURER_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                CHARLIE_TREASURER_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                TREASURE_TREASURER_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                TREASURE_TREASURER_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                ASSET_MANAGEMENT_VAULT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                ASSET_MANAGEMENT_VAULT_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                DECAY_FACTOR_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationUsdc.grantRole(
                DECAY_FACTOR_VALUE_ROLE,
                admin
            );

            await deployer.deploy(
                IporAssetConfiguration,
                process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS,
                ipDaiToken.address
            );
            iporAssetConfigurationDai = await IporAssetConfiguration.deployed();
            await iporAssetConfigurationDai.grantRole(
                INCOME_TAX_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                INCOME_TAX_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                LIQUIDATION_DEPOSIT_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                OPENING_FEE_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                OPENING_FEE_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                IPOR_PUBLICATION_FEE_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                MAX_POSITION_TOTAL_AMOUNT_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                SPREAD_PAY_FIXED_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                SPREAD_REC_FIXED_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                SPREAD_REC_FIXED_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                COLLATERALIZATION_FACTOR_VALUE_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                CHARLIE_TREASURER_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                CHARLIE_TREASURER_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                TREASURE_TREASURER_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                TREASURE_TREASURER_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                ASSET_MANAGEMENT_VAULT_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                ASSET_MANAGEMENT_VAULT_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                DECAY_FACTOR_VALUE_ADMIN_ROLE,
                admin
            );
            await iporAssetConfigurationDai.grantRole(
                DECAY_FACTOR_VALUE_ROLE,
                admin
            );

            await iporConfiguration.addAsset(mockedDai.address);
            await iporConfiguration.addAsset(mockedUsdt.address);
            await iporConfiguration.addAsset(mockedUsdc.address);

            await iporConfiguration.setIporAssetConfiguration(
                process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS,
                await IporAssetConfigurationUsdt.address
            );
            await iporConfiguration.setIporAssetConfiguration(
                process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS,
                await IporAssetConfigurationUsdc.address
            );
            await iporConfiguration.setIporAssetConfiguration(
                process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS,
                await IporAssetConfigurationDai.address
            );
        }
    }

    if (_network !== "test") {
        // await deployer.link(AmmMath, Milton);
        await deployer.deploy(Milton);
        milton = await Milton.deployed();

        // await deployer.link(AmmMath, Joseph);
        await deployer.deploy(Joseph);
        joseph = await Joseph.deployed();

        await deployer.deploy(MiltonStorage);
        miltonStorage = await MiltonStorage.deployed();

        //initial addresses setup
        await iporConfiguration.setWarren(warren.address);
        await iporConfiguration.setWarrenStorage(warrenStorage.address);
        await iporConfiguration.setMiltonStorage(miltonStorage.address);

        if (isTestEnvironment === 1) {
            //TestWarren
            // await deployer.link(AmmMath, TestWarren);
            await deployer.link(IporLogic, TestWarren);
            await deployer.deploy(TestWarren, warrenStorage.address);
            let testWarren = await TestWarren.deployed();
            await warrenStorage.addUpdater(testWarren.address);

            //TestMilton
            // await deployer.link(AmmMath, TestMilton);
            await deployer.link(DerivativeLogic, TestMilton);
            await deployer.deploy(TestMilton);
            testMilton = await TestMilton.deployed();

            //TestJoseph
            // await deployer.link(AmmMath, TestJoseph);
            await deployer.deploy(TestJoseph);
            testJoseph = await TestJoseph.deployed();

            if (
                _network === "develop" ||
                _network === "develop2" ||
                _network === "dev" ||
                _network === "docker" ||
                _network === "soliditycoverage"
            ) {
                if (process.env.PRIV_TEST_NETWORK_USE_TEST_MILTON === "true") {
                    //For IPOR Test Framework purposes
                    await iporConfiguration.setMilton(testMilton.address);
                } else {
                    //Web application, IPOR Dev Tool
                    await iporConfiguration.setMilton(milton.address);
                }

                if (process.env.PRIV_TEST_NETWORK_USE_TEST_JOSEPH === "true") {
                    //For IPOR Test Framework purposes
                    await iporConfiguration.setJoseph(testJoseph.address);
                } else {
                    //Web application, IPOR Dev Tool
                    await iporConfiguration.setJoseph(joseph.address);
                }
            } else {
                await iporConfiguration.setMilton(milton.address);
                await iporConfiguration.setJoseph(joseph.address);
            }
            await testWarren.initialize(iporConfiguration.address);
            await testMilton.initialize(iporConfiguration.address);
            await testJoseph.initialize(iporConfiguration.address);
        } else {
            await iporConfiguration.setMilton(milton.address);
        }

        await warren.initialize(iporConfiguration.address);
        await warrenStorage.initialize(iporConfiguration.address);
        await milton.initialize(iporConfiguration.address);
        await miltonStorage.initialize(iporConfiguration.address);
        await joseph.initialize(iporConfiguration.address);
    } else {
        // await deployer.link(AmmMath, TestWarren);
        await deployer.link(IporLogic, TestWarren);
        await deployer.link(DerivativeLogic, TestMilton);
        // await deployer.link(AmmMath, TestMilton);
        // await deployer.link(AmmMath, TestJoseph);
        // await deployer.link(AmmMath, WarrenDevToolDataProvider);
        await deployer.deploy(
            WarrenDevToolDataProvider,
            iporConfiguration.address
        );
    }

    //Prepare tokens for initial accounts...
    if (
        _network === "develop" ||
        _network === "develop2" ||
        _network === "dev" ||
        _network === "docker" ||
        _network === "soliditycoverage"
    ) {
        console.log("Setup Faucet...");
        await mockedUsdt.transfer(miltonFaucet.address, faucetSupply6Decimals);
        await mockedUsdc.transfer(miltonFaucet.address, faucetSupply6Decimals);
        await mockedDai.transfer(miltonFaucet.address, faucetSupply18Decimals);
        console.log("Setup Faucet finished.");

        console.log("Start transfer TOKENS to test addresses...");

        //first address is an admin, last two addresses will not have tokens and approves
        for (let i = 0; i < addresses.length - 2; i++) {
            await mockedUsdt.transfer(addresses[i], userSupply6Decimals);
            await mockedUsdc.transfer(addresses[i], userSupply6Decimals);
            await mockedDai.transfer(addresses[i], userSupply18Decimals);

            console.log(`Account: ${addresses[i]} - tokens transferred`);

            //Milton has rights to spend money on behalf of user
            mockedUsdt.approve(milton.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedUsdc.approve(milton.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedDai.approve(milton.address, totalSupply18Decimals, {
                from: addresses[i],
            });

            mockedUsdt.approve(joseph.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedUsdc.approve(joseph.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedDai.approve(joseph.address, totalSupply18Decimals, {
                from: addresses[i],
            });

            console.log(
                `Account: ${addresses[i]} approve spender Milton ${milton.address} to spend tokens on behalf of user.`
            );
            console.log(
                `Account: ${addresses[i]} approve spender Joseph ${joseph.address} to spend tokens on behalf of user.`
            );

            if (isTestEnvironment === 1) {
                mockedUsdt.approve(testMilton.address, totalSupply6Decimals, {
                    from: addresses[i],
                });
                mockedUsdc.approve(testMilton.address, totalSupply6Decimals, {
                    from: addresses[i],
                });
                mockedDai.approve(testMilton.address, totalSupply18Decimals, {
                    from: addresses[i],
                });

                mockedUsdt.approve(testJoseph.address, totalSupply6Decimals, {
                    from: addresses[i],
                });
                mockedUsdc.approve(testJoseph.address, totalSupply6Decimals, {
                    from: addresses[i],
                });
                mockedDai.approve(testJoseph.address, totalSupply18Decimals, {
                    from: addresses[i],
                });

                console.log(
                    `Account: ${addresses[i]} approve spender TestMilton ${testMilton.address} to spend tokens on behalf of user.`
                );
                console.log(
                    `Account: ${addresses[i]} approve spender TestJoseph ${testJoseph.address} to spend tokens on behalf of user.`
                );
            }
        }

        await milton.authorizeJoseph(mockedUsdt.address);
        await milton.authorizeJoseph(mockedUsdc.address);
        await milton.authorizeJoseph(mockedDai.address);

        await testMilton.authorizeJoseph(mockedUsdt.address);
        await testMilton.authorizeJoseph(mockedUsdc.address);
        await testMilton.authorizeJoseph(mockedDai.address);

        await miltonStorage.addAsset(mockedDai.address);
        await miltonStorage.addAsset(mockedUsdc.address);
        await miltonStorage.addAsset(mockedUsdt.address);

        await warrenStorage.addUpdater(admin);
        await warrenStorage.addUpdater(warren.address);

        if (process.env.INITIAL_IPOR_MIGRATION_ENABLED === "true") {
            console.log("Prepare initial IPOR migration...");
            await warren.updateIndexes(
                [mockedDai.address, mockedUsdt.address, mockedUsdc.address],
                [
                    BigInt("30000000000000000"),
                    BigInt("30000000000000000"),
                    BigInt("30000000000000000"),
                ]
            );
        }
    }

    await miltonLPUtilizationStrategyCollateral.initialize(
        iporConfiguration.address
    );
    await miltonSpreadStrategy.initialize(iporConfiguration.address);
};
