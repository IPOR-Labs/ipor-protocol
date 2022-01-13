require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const Warren = artifacts.require("Warren");
const WarrenStorage = artifacts.require("WarrenStorage");
const Milton = artifacts.require("Milton");
const MiltonStorage = artifacts.require("MiltonStorage");
const MiltonFaucet = artifacts.require("MiltonFaucet");
const ItfWarren = artifacts.require("ItfWarren");
const ItfMilton = artifacts.require("ItfMilton");
const ItfJoseph = artifacts.require("ItfJoseph");
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
const IporMath = artifacts.require("IporMath");
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
const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
const Joseph = artifacts.require("Joseph");

async function grandRolesForAssetConfiguration(admin, iporAssetConfiguration) {
    await iporAssetConfiguration.grantRole(
        keccak256("ROLES_INFO_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfiguration.grantRole(keccak256("ROLES_INFO_ROLE"), admin);

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
    let itfMilton = null;
    let joseph = null;
    let itfJoseph = null;
    let miltonStorage = null;
    let miltonFaucet = null;
    let iporAssetConfigurationUsdt = null;
    let iporAssetConfigurationUsdc = null;
    let iporAssetConfigurationDai = null;
    let iporConfiguration = null;

    await deployer.deploy(IporMath);

    await deployer.deploy(IporLogic);

    await deployer.link(IporLogic, Warren);
    await deployer.link(IporLogic, WarrenStorage);    

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

    await deployer.deploy(IporConfiguration);
    iporConfiguration = await IporConfiguration.deployed();

	await deployer.deploy(WarrenStorage, iporConfiguration.address);
    let warrenStorage = await WarrenStorage.deployed();

    await deployer.deploy(Warren, iporConfiguration.address);
    let warren = await Warren.deployed();

    await deployer.deploy(
        MiltonFrontendDataProvider,
        iporConfiguration.address
    );

    // await deployer.link(IporMath, WarrenFrontendDataProvider);
    await deployer.deploy(
        WarrenFrontendDataProvider,
        iporConfiguration.address
    );

    // await deployer.link(IporMath, MiltonLPUtilizationStrategyCollateral);
    await deployer.deploy(MiltonLPUtilizationStrategyCollateral, iporConfiguration.address);
    let miltonLPUtilizationStrategyCollateral =
        await MiltonLPUtilizationStrategyCollateral.deployed();

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

    await iporConfiguration.grantRole(keccak256("MILTON_ADMIN_ROLE"), admin);
    await iporConfiguration.grantRole(keccak256("MILTON_ROLE"), admin);

    await iporConfiguration.grantRole(
        keccak256("MILTON_STORAGE_ADMIN_ROLE"),
        admin
    );
    await iporConfiguration.grantRole(keccak256("MILTON_STORAGE_ROLE"), admin);

    await iporConfiguration.grantRole(keccak256("JOSEPH_ADMIN_ROLE"), admin);
    await iporConfiguration.grantRole(keccak256("JOSEPH_ROLE"), admin);

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
    await iporConfiguration.setMiltonLPUtilizationStrategy(
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
        await deployer.deploy(UsdtMockedToken, totalSupply6Decimals, 6);
        mockedUsdt = await UsdtMockedToken.deployed();
        await iporConfiguration.addAsset(mockedUsdt.address);
        await deployer.deploy(IpToken, mockedUsdt.address, "IP USDT", "ipUSDT");
        ipUsdtToken = await IpToken.deployed();
        await ipUsdtToken.initialize(iporConfiguration.address);
        await deployer.deploy(
            IporAssetConfigurationUsdt,
            mockedUsdt.address,
            ipUsdtToken.address
        );
        iporAssetConfigurationUsdt =
            await IporAssetConfigurationUsdt.deployed();
        await iporConfiguration.setIporAssetConfiguration(
            mockedUsdt.address,
            await iporAssetConfigurationUsdt.address
        );

        await deployer.deploy(UsdcMockedToken, totalSupply6Decimals, 6);
        mockedUsdc = await UsdcMockedToken.deployed();
        await iporConfiguration.addAsset(mockedUsdc.address);
        await deployer.deploy(IpToken, mockedUsdc.address, "IP USDC", "ipUSDC");
        ipUsdcToken = await IpToken.deployed();
        await ipUsdcToken.initialize(iporConfiguration.address);
        await deployer.deploy(
            IporAssetConfigurationUsdc,
            mockedUsdc.address,
            ipUsdcToken.address
        );
        iporAssetConfigurationUsdc =
            await IporAssetConfigurationUsdc.deployed();
        await iporConfiguration.setIporAssetConfiguration(
            mockedUsdc.address,
            await iporAssetConfigurationUsdc.address
        );

        await deployer.deploy(DaiMockedToken, totalSupply18Decimals, 18);
        mockedDai = await DaiMockedToken.deployed();
        await iporConfiguration.addAsset(mockedDai.address);
        await deployer.deploy(IpToken, mockedDai.address, "IP DAI", "ipDAI");
        ipDaiToken = await IpToken.deployed();
        await ipDaiToken.initialize(iporConfiguration.address);
        await deployer.deploy(
            IporAssetConfigurationDai,
            mockedDai.address,
            ipDaiToken.address
        );
        iporAssetConfigurationDai = await IporAssetConfigurationDai.deployed();
        await iporConfiguration.setIporAssetConfiguration(
            mockedDai.address,
            await iporAssetConfigurationDai.address
        );

        //#####################################################################
        //GRANT ROLE IPOR ASSET CONFIGURATION  - BEGIN
        //#####################################################################
        await grandRolesForAssetConfiguration(
            admin,
            iporAssetConfigurationUsdt
        );
        await grandRolesForAssetConfiguration(
            admin,
            iporAssetConfigurationUsdc
        );
        await grandRolesForAssetConfiguration(admin, iporAssetConfigurationDai);
        //#####################################################################
        //GRANT ROLE IPOR ASSET CONFIGURATION - END
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
        if (_network !== "test") {
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

            await deployer.deploy(
                IporAssetConfiguration,
                process.env.PUB_NETWORK_TOKEN_USDT_ADDRESS,
                ipUsdtToken.address
            );
            iporAssetConfigurationUsdt =
                await IporAssetConfiguration.deployed();

            await deployer.deploy(
                IporAssetConfiguration,
                process.env.PUB_NETWORK_TOKEN_USDC_ADDRESS,
                ipUsdcToken.address
            );
            iporAssetConfigurationUsdc =
                await IporAssetConfiguration.deployed();

            await deployer.deploy(
                IporAssetConfiguration,
                process.env.PUB_NETWORK_TOKEN_DAI_ADDRESS,
                ipDaiToken.address
            );
            iporAssetConfigurationDai = await IporAssetConfiguration.deployed();

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
        await deployer.deploy(Milton, iporConfiguration.address);
        milton = await Milton.deployed();

        await deployer.deploy(Joseph, iporConfiguration.address);
        joseph = await Joseph.deployed();

        await deployer.deploy(MiltonStorage, iporConfiguration.address);
        miltonStorage = await MiltonStorage.deployed();

        //initial addresses setup
        await iporConfiguration.setWarren(warren.address);
        await iporConfiguration.setWarrenStorage(warrenStorage.address);
        await iporConfiguration.setMiltonStorage(miltonStorage.address);

        if (isTestEnvironment === 1) {
            //ItfWarren
            // await deployer.link(IporMath, ItfWarren);
            await deployer.link(IporLogic, ItfWarren);
            await deployer.deploy(ItfWarren, iporConfiguration.address);
            let itfWarren = await ItfWarren.deployed();
            await warrenStorage.addUpdater(itfWarren.address);

            //ItfMilton
            // await deployer.link(IporMath, ItfMilton);
            await deployer.link(DerivativeLogic, ItfMilton);
            await deployer.deploy(ItfMilton, iporConfiguration.address);
            itfMilton = await ItfMilton.deployed();

            //ItfJoseph
            // await deployer.link(IporMath, ItfJoseph);
            await deployer.deploy(ItfJoseph, iporConfiguration.address);
            itfJoseph = await ItfJoseph.deployed();

            if (
                _network === "develop" ||
                _network === "develop2" ||
                _network === "dev" ||
                _network === "docker" ||
                _network === "soliditycoverage"
            ) {
                if (process.env.PRIV_TEST_NETWORK_USE_TEST_MILTON === "true") {
                    //For IPOR Test Framework purposes
                    await iporConfiguration.setMilton(itfMilton.address);
                } else {
                    //Web application, IPOR Dev Tool
                    await iporConfiguration.setMilton(milton.address);
                }

                if (process.env.PRIV_TEST_NETWORK_USE_TEST_JOSEPH === "true") {
                    //For IPOR Test Framework purposes
                    await iporConfiguration.setJoseph(itfJoseph.address);
                } else {
                    //Web application, IPOR Dev Tool
                    await iporConfiguration.setJoseph(joseph.address);
                }
            } else {
                await iporConfiguration.setMilton(milton.address);
                await iporConfiguration.setJoseph(joseph.address);
            }
        } else {
            await iporConfiguration.setMilton(milton.address);
        }
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
                mockedUsdt.approve(itfMilton.address, totalSupply6Decimals, {
                    from: addresses[i],
                });
                mockedUsdc.approve(itfMilton.address, totalSupply6Decimals, {
                    from: addresses[i],
                });
                mockedDai.approve(itfMilton.address, totalSupply18Decimals, {
                    from: addresses[i],
                });

                mockedUsdt.approve(itfJoseph.address, totalSupply6Decimals, {
                    from: addresses[i],
                });
                mockedUsdc.approve(itfJoseph.address, totalSupply6Decimals, {
                    from: addresses[i],
                });
                mockedDai.approve(itfJoseph.address, totalSupply18Decimals, {
                    from: addresses[i],
                });

                console.log(
                    `Account: ${addresses[i]} approve spender ItfMilton ${itfMilton.address} to spend tokens on behalf of user.`
                );
                console.log(
                    `Account: ${addresses[i]} approve spender ItfJoseph ${itfJoseph.address} to spend tokens on behalf of user.`
                );
            }
        }

        await milton.authorizeJoseph(mockedUsdt.address);
        await milton.authorizeJoseph(mockedUsdc.address);
        await milton.authorizeJoseph(mockedDai.address);

        await itfMilton.authorizeJoseph(mockedUsdt.address);
        await itfMilton.authorizeJoseph(mockedUsdc.address);
        await itfMilton.authorizeJoseph(mockedDai.address);

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
};
