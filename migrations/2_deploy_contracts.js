require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");

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

async function grandRolesForAssetConfiguration(admin, iporAssetConfiguration) {
    await iporAssetConfiguration.grantRole(
        keccak256("ROLES_INFO_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(keccak256("ROLES_INFO_ROLE"), admin);

    await iporAssetConfiguration.grantRole(
        keccak256("MILTON_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(keccak256("MILTON_ROLE"), admin);

    await iporAssetConfiguration.grantRole(
        keccak256("MILTON_STORAGE_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("MILTON_STORAGE_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("JOSEPH_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(keccak256("JOSEPH_ROLE"), admin);

    await iporAssetConfiguration.grantRole(
        keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("INCOME_TAX_PERCENTAGE_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("OPENING_FEE_PERCENTAGE_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("DECAY_FACTOR_VALUE_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("DECAY_FACTOR_VALUE_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("ASSET_MANAGEMENT_VAULT_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("CHARLIE_TREASURER_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("CHARLIE_TREASURER_ROLE"),
        admin
    );

    await iporAssetConfiguration.grantRole(
        keccak256("TREASURE_TREASURER_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(
        keccak256("TREASURE_TREASURER_ROLE"),
        admin
    );
}

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;

    let isMainet = false;

    if (_network === "mainnet") {
        isMainet = true;
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
    let warren = null;
    let itfWarren = null;
    let miltonUsdt = null;
    let miltonUsdc = null;
    let miltonDai = null;
    let miltonStorageUsdt = null;
    let miltonStorageUsdc = null;
    let miltonStorageDai = null;
    let itfMiltonUsdt = null;
    let itfMiltonUsdc = null;
    let itfMiltonDai = null;
    let josephUsdt = null;
    let josephUsdc = null;
    let josephDai = null;
    let itfJosephUsdt = null;
    let itfJosephUsdc = null;
    let itfJosephDai = null;
    let iporAssetConfigurationUsdt = null;
    let iporAssetConfigurationUsdc = null;
    let iporAssetConfigurationDai = null;

    let miltonFaucet = null;
    let iporConfiguration = null;

    await deployer.deploy(IporConfiguration);
    iporConfiguration = await IporConfiguration.deployed();

    await deployer.deploy(Warren, iporConfiguration.address);
    warren = await Warren.deployed();

    await deployer.deploy(
        MiltonFrontendDataProvider,
        iporConfiguration.address
    );

    await deployer.deploy(
        WarrenFrontendDataProvider,
        iporConfiguration.address
    );

    await deployer.deploy(
        MiltonLiquidityPoolUtilizationModel,
        iporConfiguration.address
    );
    let miltonLPUtilizationStrategyCollateral =
        await MiltonLiquidityPoolUtilizationModel.deployed();

    await deployer.deploy(MiltonSpreadModel, iporConfiguration.address);
    let miltonSpreadModel = await MiltonSpreadModel.deployed();

    //#####################################################################
    //GRANT ROLE IPOR CONFIGURATION  - BEGIN
    //#####################################################################

    await iporConfiguration.grantRole(
        keccak256("ROLES_INFO_ADMIN_ROLE"),
        admin
    );
    await iporConfiguration.grantRole(keccak256("ROLES_INFO_ROLE"), admin);

    await iporConfiguration.grantRole(
        keccak256("IPOR_ASSETS_ADMIN_ROLE"),
        admin
    );
    await iporConfiguration.grantRole(keccak256("IPOR_ASSETS_ROLE"), admin);

    await iporConfiguration.grantRole(
        keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
        admin
    );
    await iporConfiguration.grantRole(
        keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
        admin
    );

    await iporConfiguration.grantRole(keccak256("WARREN_ADMIN_ROLE"), admin);
    await iporConfiguration.grantRole(keccak256("WARREN_ROLE"), admin);

    await iporConfiguration.grantRole(
        keccak256("WARREN_STORAGE_ADMIN_ROLE"),
        admin
    );
    await iporConfiguration.grantRole(keccak256("WARREN_STORAGE_ROLE"), admin);

    await iporConfiguration.grantRole(
        keccak256("MILTON_SPREAD_MODEL_ADMIN_ROLE"),
        admin
    );
    await iporConfiguration.grantRole(
        keccak256("MILTON_SPREAD_MODEL_ROLE"),
        admin
    );

    await iporConfiguration.grantRole(
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE"),
        admin
    );
    await iporConfiguration.grantRole(
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE"),
        admin
    );

    await iporConfiguration.grantRole(
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"),
        admin
    );
    await iporConfiguration.grantRole(
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"),
        admin
    );
    //#####################################################################
    //GRANT ROLE IPOR CONFIGURATION - END
    //#####################################################################

    await iporConfiguration.setMiltonSpreadModel(miltonSpreadModel.address);
    await iporConfiguration.setMiltonLiquidityPoolUtilizationModel(
        miltonLPUtilizationStrategyCollateral.address
    );

    // prepare ERC20 mocked tokens...
    if (
        _network === "develop" ||
        _network === "develop2" ||
        _network === "dev" ||
        _network === "docker" ||
        _network === "soliditycoverage"
    ) {
        //#####################################################################
        // CONFIG USDT - BEGIN
        //#####################################################################
        await deployer.deploy(UsdtMockedToken, totalSupply6Decimals, 6);
        mockedUsdt = await UsdtMockedToken.deployed();
        await iporConfiguration.addAsset(mockedUsdt.address);
        await deployer.deploy(IpToken, mockedUsdt.address, "IP USDT", "ipUSDT");
        ipUsdtToken = await IpToken.deployed();

        await deployer.deploy(
            IporAssetConfigurationUsdt,
            mockedUsdt.address,
            ipUsdtToken.address
        );
        iporAssetConfigurationUsdt =
            await IporAssetConfigurationUsdt.deployed();

        await ipUsdtToken.initialize(iporAssetConfigurationUsdt.address);

        await iporConfiguration.setIporAssetConfiguration(
            mockedUsdt.address,
            await iporAssetConfigurationUsdt.address
        );

        await deployer.deploy(
            MiltonStorageUsdt,
            mockedUsdt.address,
            iporConfiguration.address
        );
        miltonStorageUsdt = await MiltonStorageUsdt.deployed();

        await grandRolesForAssetConfiguration(
            admin,
            iporAssetConfigurationUsdt
        );

        await iporAssetConfigurationUsdt.setMiltonStorage(
            miltonStorageUsdt.address
        );

        //#####################################################################
        // CONFIG USDT - END
        //#####################################################################

        //#####################################################################
        // CONFIG USDC - BEGIN
        //#####################################################################

        await deployer.deploy(UsdcMockedToken, totalSupply6Decimals, 6);
        mockedUsdc = await UsdcMockedToken.deployed();
        await iporConfiguration.addAsset(mockedUsdc.address);
        await deployer.deploy(IpToken, mockedUsdc.address, "IP USDC", "ipUSDC");
        ipUsdcToken = await IpToken.deployed();

        await deployer.deploy(
            IporAssetConfigurationUsdc,
            mockedUsdc.address,
            ipUsdcToken.address
        );

        iporAssetConfigurationUsdc =
            await IporAssetConfigurationUsdc.deployed();

        await ipUsdcToken.initialize(iporAssetConfigurationUsdc.address);

        await iporConfiguration.setIporAssetConfiguration(
            mockedUsdc.address,
            await iporAssetConfigurationUsdc.address
        );
        await deployer.deploy(
            MiltonStorageUsdc,
            mockedUsdc.address,
            iporConfiguration.address
        );
        miltonStorageUsdc = await MiltonStorageUsdc.deployed();

        await grandRolesForAssetConfiguration(
            admin,
            iporAssetConfigurationUsdc
        );

        await iporAssetConfigurationUsdc.setMiltonStorage(
            miltonStorageUsdc.address
        );

        //#####################################################################
        // CONFIG USDC - END
        //#####################################################################

        //#####################################################################
        // CONFIG DAI - BEGIN
        //#####################################################################

        await deployer.deploy(DaiMockedToken, totalSupply18Decimals, 18);
        mockedDai = await DaiMockedToken.deployed();
        await iporConfiguration.addAsset(mockedDai.address);
        await deployer.deploy(IpToken, mockedDai.address, "IP DAI", "ipDAI");
        ipDaiToken = await IpToken.deployed();

        await deployer.deploy(
            IporAssetConfigurationDai,
            mockedDai.address,
            ipDaiToken.address
        );
        iporAssetConfigurationDai = await IporAssetConfigurationDai.deployed();

        await ipDaiToken.initialize(iporAssetConfigurationDai.address);

        await iporConfiguration.setIporAssetConfiguration(
            mockedDai.address,
            await iporAssetConfigurationDai.address
        );
        await deployer.deploy(
            MiltonStorageDai,
            mockedDai.address,
            iporConfiguration.address
        );
        miltonStorageDai = await MiltonStorageDai.deployed();

        await grandRolesForAssetConfiguration(admin, iporAssetConfigurationDai);

        await iporAssetConfigurationDai.setMiltonStorage(
            miltonStorageDai.address
        );

        //#####################################################################
        // CONFIG DAI - END
        //#####################################################################

        //#####################################################################
        //GRANT ROLE MILTON SPREAD CONFIGURATION  - BEGIN
        //#####################################################################
        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_MAX_VALUE_ADMIN_ROLE"),
            admin
        );
        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_MAX_VALUE_ROLE"),
            admin
        );

        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE"),
            admin
        );
        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE"),
            admin
        );

        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE"),
            admin
        );
        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE"),
            admin
        );

        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE"),
            admin
        );
        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE"),
            admin
        );

        await miltonSpreadModel.grantRole(
            keccak256(
                "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE"
            ),
            admin
        );
        await miltonSpreadModel.grantRole(
            keccak256(
                "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE"
            ),
            admin
        );

        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE"),
            admin
        );
        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE"),
            admin
        );

        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE"),
            admin
        );
        await miltonSpreadModel.grantRole(
            keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE"),
            admin
        );

        //#####################################################################
        //GRANT ROLE MILTON SPREAD CONFIGURATION - END
        //#####################################################################

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
            WarrenDevToolDataProvider,
            iporConfiguration.address
        );
        await deployer.deploy(
            MiltonDevToolDataProvider,
            iporConfiguration.address
        );
    } else {
        //PUBLIC TEST NETWORK AND PRODUCTION

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

        await deployer.deploy(
            IporAssetConfiguration,
            process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS,
            ipUsdtToken.address
        );
        iporAssetConfigurationUsdt = await IporAssetConfiguration.deployed();

        await deployer.deploy(
            IporAssetConfiguration,
            process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS,
            ipUsdcToken.address
        );
        iporAssetConfigurationUsdc = await IporAssetConfiguration.deployed();

        await deployer.deploy(
            IporAssetConfiguration,
            process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS,
            ipDaiToken.address
        );
        iporAssetConfigurationDai = await IporAssetConfiguration.deployed();

        await iporConfiguration.setIporAssetConfiguration(
            process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS,
            await iporAssetConfigurationUsdt.address
        );
        await deployer.deploy(
            MiltonStorageUsdt,
            process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS,
            iporConfiguration.address
        );
        miltonStorageUsdt = await MiltonStorageUsdt.deployed();
        await iporAssetConfigurationUsdt.setMiltonStorage(
            miltonStorageUsdt.address
        );

        await iporConfiguration.setIporAssetConfiguration(
            process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS,
            await iporAssetConfigurationUsdc.address
        );
        // await deployer.deploy(
        //     MiltonStorageUsdc,
        //     process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS,
        //     iporConfiguration.address
        // );
        // miltonStorageUsdc = await MiltonStorageUsdc.deployed();
        // await iporAssetConfigurationUsdc.setMiltonStorage(
        //     miltonStorageUsdc.address
        // );

        await iporConfiguration.setIporAssetConfiguration(
            process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS,
            await iporAssetConfigurationDai.address
        );
        await deployer.deploy(
            MiltonStorageDai,
            process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS,
            iporConfiguration.address
        );
        miltonStorageDai = await MiltonStorageDai.deployed();
        await iporAssetConfigurationDai.setMiltonStorage(
            miltonStorageDai.address
        );
    }

    if (isMainet === false) {
        if (process.env.ITF_ENABLED === "true") {
            await iporConfiguration.setWarren(itfWarren.address);
        } else {
            await iporConfiguration.setWarren(warren.address);
        }

        await deployer.deploy(ItfWarren, iporConfiguration.address);
        itfWarren = await ItfWarren.deployed();
        await itfWarren.addUpdater(admin);

        await deployer.deploy(
            MiltonUsdt,
            mockedUsdt.address,
            iporConfiguration.address
        );
        miltonUsdt = await MiltonUsdt.deployed();

        await deployer.deploy(
            MiltonUsdc,
            mockedUsdc.address,
            iporConfiguration.address
        );
        miltonUsdc = await MiltonUsdc.deployed();

        await deployer.deploy(
            MiltonDai,
            mockedDai.address,
            iporConfiguration.address
        );
        miltonDai = await MiltonDai.deployed();

        await deployer.deploy(
            ItfMiltonUsdt,
            mockedUsdt.address,
            iporConfiguration.address
        );
        itfMiltonUsdt = await ItfMiltonUsdt.deployed();

        await deployer.deploy(
            ItfMiltonUsdc,
            mockedUsdc.address,
            iporConfiguration.address
        );
        itfMiltonUsdc = await ItfMiltonUsdc.deployed();

        await deployer.deploy(
            ItfMiltonDai,
            mockedDai.address,
            iporConfiguration.address
        );
        itfMiltonDai = await ItfMiltonDai.deployed();

        if (
            _network === "develop" ||
            _network === "develop2" ||
            _network === "dev" ||
            _network === "docker" ||
            _network === "soliditycoverage"
        ) {
            await deployer.deploy(
                JosephUsdt,
                mockedUsdt.address,
                iporConfiguration.address
            );
            josephUsdt = await JosephUsdt.deployed();

            await deployer.deploy(
                JosephUsdc,
                mockedUsdc.address,
                iporConfiguration.address
            );
            josephUsdc = await JosephUsdc.deployed();

            await deployer.deploy(
                JosephDai,
                mockedDai.address,
                iporConfiguration.address
            );
            josephDai = await JosephDai.deployed();

            await deployer.deploy(
                ItfJosephUsdt,
                mockedUsdt.address,
                iporConfiguration.address
            );
            itfJosephUsdt = await ItfJosephUsdt.deployed();

            await deployer.deploy(
                ItfJosephUsdc,
                mockedUsdc.address,
                iporConfiguration.address
            );
            itfJosephUsdc = await ItfJosephUsdc.deployed();

            await deployer.deploy(
                ItfJosephDai,
                mockedDai.address,
                iporConfiguration.address
            );
            itfJosephDai = await ItfJosephDai.deployed();

            if (process.env.ITF_ENABLED === "true") {
                //For IPOR Test Framework purposes
                await iporAssetConfigurationUsdt.setMilton(
                    itfMiltonUsdt.address
                );
                await iporAssetConfigurationUsdc.setMilton(
                    itfMiltonUsdc.address
                );
                await iporAssetConfigurationDai.setMilton(itfMiltonDai.address);
            } else {
                //Web application, IPOR Dev Tool
                await iporAssetConfigurationUsdt.setMilton(miltonUsdt.address);
                await iporAssetConfigurationUsdc.setMilton(miltonUsdc.address);
                await iporAssetConfigurationDai.setMilton(miltonDai.address);
            }

            if (process.env.ITF_ENABLED === "true") {
                //For IPOR Test Framework purposes
                await iporAssetConfigurationUsdt.setJoseph(
                    itfJosephUsdt.address
                );
                await iporAssetConfigurationUsdc.setJoseph(
                    itfJosephUsdc.address
                );
                await iporAssetConfigurationDai.setJoseph(itfJosephDai.address);
            } else {
                //Web application, IPOR Dev Tool
                await iporAssetConfigurationUsdt.setJoseph(josephUsdt.address);
                await iporAssetConfigurationUsdc.setJoseph(josephUsdc.address);
                await iporAssetConfigurationDai.setJoseph(josephDai.address);
            }
        } else {
            await iporAssetConfigurationUsdt.setMilton(miltonUsdt.address);
            await iporAssetConfigurationUsdc.setMilton(miltonUsdc.address);
            await iporAssetConfigurationDai.setMilton(miltonDai.address);

            await iporAssetConfigurationUsdt.setJoseph(josephUsdt.address);
            await iporAssetConfigurationUsdc.setJoseph(josephUsdc.address);
            await iporAssetConfigurationDai.setJoseph(josephDai.address);
        }
    } else {
        await iporAssetConfigurationUsdt.setMilton(miltonUsdt.address);
        await iporAssetConfigurationUsdc.setMilton(miltonUsdc.address);
        await iporAssetConfigurationDai.setMilton(miltonDai.address);
        await iporAssetConfigurationUsdt.setJoseph(josephUsdt.address);
        await iporAssetConfigurationUsdc.setJoseph(josephUsdc.address);
        await iporAssetConfigurationDai.setJoseph(josephDai.address);
        await iporConfiguration.setWarren(warren.address);
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
            mockedUsdt.approve(miltonUsdt.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedUsdc.approve(miltonUsdc.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedDai.approve(miltonDai.address, totalSupply18Decimals, {
                from: addresses[i],
            });

            mockedUsdt.approve(josephUsdt.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedUsdc.approve(josephUsdc.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedDai.approve(josephDai.address, totalSupply18Decimals, {
                from: addresses[i],
            });

            if (process.env.ITF_ENABLED === "true") {
                mockedUsdt.approve(
                    itfMiltonUsdt.address,
                    totalSupply6Decimals,
                    {
                        from: addresses[i],
                    }
                );
                mockedUsdc.approve(
                    itfMiltonUsdc.address,
                    totalSupply6Decimals,
                    {
                        from: addresses[i],
                    }
                );
                mockedDai.approve(itfMiltonDai.address, totalSupply18Decimals, {
                    from: addresses[i],
                });
            }

            if (process.env.ITF_ENABLED === "true") {
                mockedUsdt.approve(
                    itfJosephUsdt.address,
                    totalSupply6Decimals,
                    {
                        from: addresses[i],
                    }
                );
                mockedUsdc.approve(
                    itfJosephUsdc.address,
                    totalSupply6Decimals,
                    {
                        from: addresses[i],
                    }
                );
                mockedDai.approve(itfJosephDai.address, totalSupply18Decimals, {
                    from: addresses[i],
                });
            }
        }

        await miltonUsdt.authorizeJoseph();
        await miltonUsdc.authorizeJoseph();
        await miltonDai.authorizeJoseph();

        await itfMiltonUsdt.authorizeJoseph();
        await itfMiltonUsdc.authorizeJoseph();
        await itfMiltonDai.authorizeJoseph();

        await warren.addUpdater(admin);

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
};
