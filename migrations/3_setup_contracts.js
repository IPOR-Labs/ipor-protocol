require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonFaucet = artifacts.require("MiltonFaucet");

const IporConfiguration = artifacts.require("IporConfiguration");

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
const MiltonLiquidityPoolUtilizationModel = artifacts.require(
    "MiltonLiquidityPoolUtilizationModel"
);

const UsdtMockedToken = artifacts.require("UsdtMockedToken");
const UsdcMockedToken = artifacts.require("UsdcMockedToken");
const DaiMockedToken = artifacts.require("DaiMockedToken");

const IpTokenUsdt = artifacts.require("IpTokenUsdt");
const IpTokenUsdc = artifacts.require("IpTokenUsdc");
const IpTokenDai = artifacts.require("IpTokenDai");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

const Warren = artifacts.require("Warren");

const JosephUsdt = artifacts.require("JosephUsdt");
const JosephUsdc = artifacts.require("JosephUsdc");
const JosephDai = artifacts.require("JosephDai");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

const ItfWarren = artifacts.require("ItfWarren");

const ItfJosephUsdt = artifacts.require("ItfJosephUsdt");
const ItfJosephUsdc = artifacts.require("ItfJosephUsdc");
const ItfJosephDai = artifacts.require("ItfJosephDai");

const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");
const ItfMiltonDai = artifacts.require("ItfMiltonDai");

const IporAssetConfigurationUsdt = artifacts.require(
    "IporAssetConfigurationUsdt"
);
const IporAssetConfigurationUsdc = artifacts.require(
    "IporAssetConfigurationUsdc"
);
const IporAssetConfigurationDai = artifacts.require(
    "IporAssetConfigurationDai"
);

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;

    const faucetSupply6Decimals = "10000000000000000";
    const faucetSupply18Decimals = "10000000000000000000000000000";
    const userSupply6Decimals = "1000000000000";
    const userSupply18Decimals = "1000000000000000000000000";
    const totalSupply6Decimals = "1000000000000000000";
    const totalSupply18Decimals = "1000000000000000000000000000000";

    const iporConfiguration = await IporConfiguration.deployed();

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

    const miltonLiquidityPoolUtilizationModel =
        await MiltonLiquidityPoolUtilizationModel.deployed();
    const miltonSpreadModel = await MiltonSpreadModel.deployed();
    await iporConfiguration.setMiltonSpreadModel(miltonSpreadModel.address);
    await iporConfiguration.setMiltonLiquidityPoolUtilizationModel(
        miltonLiquidityPoolUtilizationModel.address
    );

    //#####################################################################
    // CONFIG STABLE - BEGIN
    //#####################################################################

    const mockedUsdt = await UsdtMockedToken.deployed();
    const mockedUsdc = await UsdcMockedToken.deployed();
    const mockedDai = await DaiMockedToken.deployed();

    await iporConfiguration.addAsset(mockedUsdt.address);
    await iporConfiguration.addAsset(mockedUsdc.address);
    await iporConfiguration.addAsset(mockedDai.address);

    const iporAssetConfigurationUsdt =
        await IporAssetConfigurationUsdt.deployed();
    const iporAssetConfigurationUsdc =
        await IporAssetConfigurationUsdc.deployed();
    const iporAssetConfigurationDai =
        await IporAssetConfigurationDai.deployed();

    await grandRolesForAssetConfiguration(admin, iporAssetConfigurationUsdt);
    await grandRolesForAssetConfiguration(admin, iporAssetConfigurationUsdc);
    await grandRolesForAssetConfiguration(admin, iporAssetConfigurationDai);

    await iporConfiguration.setIporAssetConfiguration(
        mockedUsdt.address,
        iporAssetConfigurationUsdt.address
    );
    await iporConfiguration.setIporAssetConfiguration(
        mockedUsdc.address,
        iporAssetConfigurationUsdc.address
    );
    await iporConfiguration.setIporAssetConfiguration(
        mockedDai.address,
        iporAssetConfigurationDai.address
    );

    const miltonStorageUsdt = await MiltonStorageUsdt.deployed();
    const miltonStorageUsdc = await MiltonStorageUsdc.deployed();
    const miltonStorageDai = await MiltonStorageDai.deployed();

    await iporAssetConfigurationUsdt.setMiltonStorage(
        miltonStorageUsdt.address
    );
    await iporAssetConfigurationUsdc.setMiltonStorage(
        miltonStorageUsdc.address
    );
    await iporAssetConfigurationDai.setMiltonStorage(miltonStorageDai.address);

    //#####################################################################
    // CONFIG STABLE - END
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

    const miltonFaucet = await MiltonFaucet.deployed();

    miltonFaucet.sendTransaction({
        from: admin,
        value: "500000000000000000000000",
    });

    const ipUsdtToken = await IpTokenUsdt.deployed();
    const ipUsdcToken = await IpTokenUsdc.deployed();
    const ipDaiToken = await IpTokenDai.deployed();

    const josephUsdt = await JosephUsdt.deployed();
    const josephUsdc = await JosephUsdc.deployed();
    const josephDai = await JosephDai.deployed();

    const miltonUsdt = await MiltonUsdt.deployed();
    const miltonUsdc = await MiltonUsdc.deployed();
    const miltonDai = await MiltonDai.deployed();

    const itfJosephUsdt = await ItfJosephUsdt.deployed();
    const itfJosephUsdc = await ItfJosephUsdc.deployed();
    const itfJosephDai = await ItfJosephDai.deployed();

    const itfMiltonUsdt = await ItfMiltonUsdt.deployed();
    const itfMiltonUsdc = await ItfMiltonUsdc.deployed();
    const itfMiltonDai = await ItfMiltonDai.deployed();

    if (process.env.ITF_ENABLED === "true") {
        //For IPOR Test Framework purposes
        await iporAssetConfigurationUsdt.setMilton(itfMiltonUsdt.address);
        await iporAssetConfigurationUsdc.setMilton(itfMiltonUsdc.address);
        await iporAssetConfigurationDai.setMilton(itfMiltonDai.address);

        await iporAssetConfigurationUsdt.setJoseph(itfJosephUsdt.address);
        await iporAssetConfigurationUsdc.setJoseph(itfJosephUsdc.address);
        await iporAssetConfigurationDai.setJoseph(itfJosephDai.address);

        await itfMiltonUsdt.authorizeJoseph();
        await itfMiltonUsdc.authorizeJoseph();
        await itfMiltonDai.authorizeJoseph();

        const itfWarren = await ItfWarren.deployed();
        await itfWarren.addUpdater(admin);
        await iporConfiguration.setWarren(itfWarren.address);

        await ipUsdtToken.setJoseph(itfJosephUsdt.address);
        await ipUsdcToken.setJoseph(itfJosephUsdc.address);
        await ipDaiToken.setJoseph(itfJosephDai.address);
    } else {
        //Web application, IPOR Dev Tool
        await iporAssetConfigurationUsdt.setMilton(miltonUsdt.address);
        await iporAssetConfigurationUsdc.setMilton(miltonUsdc.address);
        await iporAssetConfigurationDai.setMilton(miltonDai.address);

        await iporAssetConfigurationUsdt.setJoseph(josephUsdt.address);
        await iporAssetConfigurationUsdc.setJoseph(josephUsdc.address);
        await iporAssetConfigurationDai.setJoseph(josephDai.address);

        await miltonUsdt.authorizeJoseph();
        await miltonUsdc.authorizeJoseph();
        await miltonDai.authorizeJoseph();

        const warren = await Warren.deployed();
        await warren.addUpdater(admin);
        await iporConfiguration.setWarren(warren.address);

        await ipUsdtToken.setJoseph(josephUsdt.address);
        await ipUsdcToken.setJoseph(josephUsdc.address);
        await ipDaiToken.setJoseph(josephDai.address);
    }

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

        if (process.env.ITF_ENABLED === "true") {
            mockedUsdt.approve(itfMiltonUsdt.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedUsdc.approve(itfMiltonUsdc.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedDai.approve(itfMiltonDai.address, totalSupply18Decimals, {
                from: addresses[i],
            });

            mockedUsdt.approve(itfJosephUsdt.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedUsdc.approve(itfJosephUsdc.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedDai.approve(itfJosephDai.address, totalSupply18Decimals, {
                from: addresses[i],
            });
        } else {
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
        }
    }

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
};

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
