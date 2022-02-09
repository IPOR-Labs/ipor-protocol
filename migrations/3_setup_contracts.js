require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { erc1967, deployProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonFaucet = artifacts.require("MiltonFaucet");

const IporConfiguration = artifacts.require("IporConfiguration");

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
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

    const iporConfigurationProxy = await IporConfiguration.deployed();
    await grandRolesForConfiguration(admin, iporConfigurationProxy);

    const miltonSpreadModelProxy = await MiltonSpreadModel.deployed();
    await iporConfigurationProxy.setMiltonSpreadModel(
        miltonSpreadModelProxy.address
    );

    //#####################################################################
    // CONFIG STABLE - BEGIN
    //#####################################################################

    const mockedUsdt = await UsdtMockedToken.deployed();
    const mockedUsdc = await UsdcMockedToken.deployed();
    const mockedDai = await DaiMockedToken.deployed();

    await iporConfigurationProxy.addAsset(mockedUsdt.address);
    await iporConfigurationProxy.addAsset(mockedUsdc.address);
    await iporConfigurationProxy.addAsset(mockedDai.address);

    const iporAssetConfigurationUsdtProxy =
        await IporAssetConfigurationUsdt.deployed();
    const iporAssetConfigurationUsdcProxy =
        await IporAssetConfigurationUsdc.deployed();
    const iporAssetConfigurationDaiProxy =
        await IporAssetConfigurationDai.deployed();

    await grandRolesForAssetConfiguration(
        admin,
        iporAssetConfigurationUsdtProxy
    );
    await grandRolesForAssetConfiguration(
        admin,
        iporAssetConfigurationUsdcProxy
    );
    await grandRolesForAssetConfiguration(
        admin,
        iporAssetConfigurationDaiProxy
    );

    await iporConfigurationProxy.setIporAssetConfiguration(
        mockedUsdt.address,
        iporAssetConfigurationUsdtProxy.address
    );
    await iporConfigurationProxy.setIporAssetConfiguration(
        mockedUsdc.address,
        iporAssetConfigurationUsdcProxy.address
    );
    await iporConfigurationProxy.setIporAssetConfiguration(
        mockedDai.address,
        iporAssetConfigurationDaiProxy.address
    );

    const miltonStorageUsdtProxy = await MiltonStorageUsdt.deployed();
    const miltonStorageUsdcProxy = await MiltonStorageUsdc.deployed();
    const miltonStorageDaiProxy = await MiltonStorageDai.deployed();

    await iporAssetConfigurationUsdtProxy.setMiltonStorage(
        miltonStorageUsdtProxy.address
    );
    await iporAssetConfigurationUsdcProxy.setMiltonStorage(
        miltonStorageUsdcProxy.address
    );
    await iporAssetConfigurationDaiProxy.setMiltonStorage(
        miltonStorageDaiProxy.address
    );

    //#####################################################################
    // CONFIG STABLE - END
    //#####################################################################

    const miltonFaucet = await MiltonFaucet.deployed();

    miltonFaucet.sendTransaction({
        from: admin,
        value: "500000000000000000000000",
    });

    const ipUsdtToken = await IpTokenUsdt.deployed();
    const ipUsdcToken = await IpTokenUsdc.deployed();
    const ipDaiToken = await IpTokenDai.deployed();

    const josephUsdtProxy = await JosephUsdt.deployed();
    const josephUsdcProxy = await JosephUsdc.deployed();
    const josephDaiProxy = await JosephDai.deployed();

    const itfJosephUsdtProxy = await ItfJosephUsdt.deployed();
    const itfJosephUsdcProxy = await ItfJosephUsdc.deployed();
    const itfJosephDaiProxy = await ItfJosephDai.deployed();

    const miltonUsdtProxy = await MiltonUsdt.deployed();
    const miltonUsdcProxy = await MiltonUsdc.deployed();
    const miltonDaiProxy = await MiltonDai.deployed();

    const itfMiltonUsdtProxy = await ItfMiltonUsdt.deployed();
    const itfMiltonUsdcProxy = await ItfMiltonUsdc.deployed();
    const itfMiltonDaiProxy = await ItfMiltonDai.deployed();

    if (process.env.ITF_ENABLED === "true") {
        //For IPOR Test Framework purposes
        await iporAssetConfigurationUsdtProxy.setMilton(
            itfMiltonUsdtProxy.address
        );
        await iporAssetConfigurationUsdcProxy.setMilton(
            itfMiltonUsdcProxy.address
        );
        await iporAssetConfigurationDaiProxy.setMilton(
            itfMiltonDaiProxy.address
        );

        await iporAssetConfigurationUsdtProxy.setJoseph(
            itfJosephUsdtProxy.address
        );
        await iporAssetConfigurationUsdcProxy.setJoseph(
            itfJosephUsdcProxy.address
        );
        await iporAssetConfigurationDaiProxy.setJoseph(
            itfJosephDaiProxy.address
        );

        await itfMiltonUsdtProxy.authorizeJoseph(itfJosephUsdtProxy.address);
        await itfMiltonUsdcProxy.authorizeJoseph(itfJosephUsdcProxy.address);
        await itfMiltonDaiProxy.authorizeJoseph(itfJosephDaiProxy.address);

        const itfWarrenProxy = await ItfWarren.deployed();

        await itfWarrenProxy.addUpdater(admin);
        await itfWarrenProxy.addAsset(mockedUsdt.address);
        await itfWarrenProxy.addAsset(mockedUsdc.address);
        await itfWarrenProxy.addAsset(mockedDai.address);

        await iporConfigurationProxy.setWarren(itfWarrenProxy.address);

        await ipUsdtToken.setJoseph(itfJosephUsdtProxy.address);
        await ipUsdcToken.setJoseph(itfJosephUsdcProxy.address);
        await ipDaiToken.setJoseph(itfJosephDaiProxy.address);

        await miltonStorageUsdtProxy.setJoseph(itfJosephUsdtProxy.address);
        await miltonStorageUsdcProxy.setJoseph(itfJosephUsdcProxy.address);
        await miltonStorageDaiProxy.setJoseph(itfJosephDaiProxy.address);

        await miltonStorageUsdtProxy.setMilton(itfMiltonUsdtProxy.address);
        await miltonStorageUsdcProxy.setMilton(itfMiltonUsdcProxy.address);
        await miltonStorageDaiProxy.setMilton(itfMiltonDaiProxy.address);
    } else {
        //Web application, IPOR Dev Tool
        await iporAssetConfigurationUsdtProxy.setMilton(
            miltonUsdtProxy.address
        );
        await iporAssetConfigurationUsdcProxy.setMilton(
            miltonUsdcProxy.address
        );
        await iporAssetConfigurationDaiProxy.setMilton(miltonDaiProxy.address);

        await iporAssetConfigurationUsdtProxy.setJoseph(
            josephUsdtProxy.address
        );
        await iporAssetConfigurationUsdcProxy.setJoseph(
            josephUsdcProxy.address
        );
        await iporAssetConfigurationDaiProxy.setJoseph(josephDaiProxy.address);

        await miltonUsdtProxy.authorizeJoseph(josephUsdtProxy.address);
        await miltonUsdcProxy.authorizeJoseph(josephUsdcProxy.address);
        await miltonDaiProxy.authorizeJoseph(josephDaiProxy.address);

        const warrenProxy = await Warren.deployed();
        await warrenProxy.addUpdater(admin);
        await warrenProxy.addAsset(mockedUsdt.address);
        await warrenProxy.addAsset(mockedUsdc.address);
        await warrenProxy.addAsset(mockedDai.address);

        await iporConfigurationProxy.setWarren(warrenProxy.address);

        await ipUsdtToken.setJoseph(josephUsdtProxy.address);
        await ipUsdcToken.setJoseph(josephUsdcProxy.address);
        await ipDaiToken.setJoseph(josephDaiProxy.address);

        await miltonStorageUsdtProxy.setJoseph(josephUsdtProxy.address);
        await miltonStorageUsdcProxy.setJoseph(josephUsdcProxy.address);
        await miltonStorageDaiProxy.setJoseph(josephDaiProxy.address);

        await miltonStorageUsdtProxy.setMilton(miltonUsdtProxy.address);
        await miltonStorageUsdcProxy.setMilton(miltonUsdcProxy.address);
        await miltonStorageDaiProxy.setMilton(miltonDaiProxy.address);
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
            mockedUsdt.approve(
                itfMiltonUsdtProxy.address,
                totalSupply6Decimals,
                {
                    from: addresses[i],
                }
            );
            mockedUsdc.approve(
                itfMiltonUsdcProxy.address,
                totalSupply6Decimals,
                {
                    from: addresses[i],
                }
            );
            mockedDai.approve(
                itfMiltonDaiProxy.address,
                totalSupply18Decimals,
                {
                    from: addresses[i],
                }
            );

            mockedUsdt.approve(
                itfJosephUsdtProxy.address,
                totalSupply6Decimals,
                {
                    from: addresses[i],
                }
            );
            mockedUsdc.approve(
                itfJosephUsdcProxy.address,
                totalSupply6Decimals,
                {
                    from: addresses[i],
                }
            );
            mockedDai.approve(
                itfJosephDaiProxy.address,
                totalSupply18Decimals,
                {
                    from: addresses[i],
                }
            );
        } else {
            //Milton has rights to spend money on behalf of user
            mockedUsdt.approve(miltonUsdtProxy.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedUsdc.approve(miltonUsdcProxy.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedDai.approve(miltonDaiProxy.address, totalSupply18Decimals, {
                from: addresses[i],
            });

            mockedUsdt.approve(josephUsdtProxy.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedUsdc.approve(josephUsdcProxy.address, totalSupply6Decimals, {
                from: addresses[i],
            });
            mockedDai.approve(josephDaiProxy.address, totalSupply18Decimals, {
                from: addresses[i],
            });
        }
    }

    if (process.env.INITIAL_IPOR_MIGRATION_ENABLED === "true") {
        console.log("Prepare initial IPOR migration...");
        await warrenProxy.updateIndexes(
            [mockedDai.address, mockedUsdt.address, mockedUsdc.address],
            [
                BigInt("30000000000000000"),
                BigInt("30000000000000000"),
                BigInt("30000000000000000"),
            ]
        );
    }
};
async function grandRolesForConfiguration(admin, iporConfigurationProxy) {
    await iporConfigurationProxy.grantRole(
        keccak256("ROLES_INFO_ADMIN_ROLE"),
        admin
    );
    await iporConfigurationProxy.grantRole(keccak256("ROLES_INFO_ROLE"), admin);

    await iporConfigurationProxy.grantRole(
        keccak256("IPOR_ASSETS_ADMIN_ROLE"),
        admin
    );
    await iporConfigurationProxy.grantRole(
        keccak256("IPOR_ASSETS_ROLE"),
        admin
    );

    await iporConfigurationProxy.grantRole(
        keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE"),
        admin
    );
    await iporConfigurationProxy.grantRole(
        keccak256("IPOR_ASSET_CONFIGURATION_ROLE"),
        admin
    );

    await iporConfigurationProxy.grantRole(
        keccak256("WARREN_ADMIN_ROLE"),
        admin
    );
    await iporConfigurationProxy.grantRole(keccak256("WARREN_ROLE"), admin);

    await iporConfigurationProxy.grantRole(
        keccak256("WARREN_STORAGE_ADMIN_ROLE"),
        admin
    );
    await iporConfigurationProxy.grantRole(
        keccak256("WARREN_STORAGE_ROLE"),
        admin
    );

    await iporConfigurationProxy.grantRole(
        keccak256("MILTON_SPREAD_MODEL_ADMIN_ROLE"),
        admin
    );
    await iporConfigurationProxy.grantRole(
        keccak256("MILTON_SPREAD_MODEL_ROLE"),
        admin
    );

    await iporConfigurationProxy.grantRole(
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE"),
        admin
    );
    await iporConfigurationProxy.grantRole(
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE"),
        admin
    );
}
async function grandRolesForAssetConfiguration(
    admin,
    iporAssetConfigurationProxy
) {
    await iporAssetConfigurationProxy.grantRole(
        keccak256("ROLES_INFO_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfigurationProxy.grantRole(
        keccak256("ROLES_INFO_ROLE"),
        admin
    );

    await iporAssetConfigurationProxy.grantRole(
        keccak256("MILTON_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfigurationProxy.grantRole(
        keccak256("MILTON_ROLE"),
        admin
    );

    await iporAssetConfigurationProxy.grantRole(
        keccak256("MILTON_STORAGE_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfigurationProxy.grantRole(
        keccak256("MILTON_STORAGE_ROLE"),
        admin
    );

    await iporAssetConfigurationProxy.grantRole(
        keccak256("JOSEPH_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfigurationProxy.grantRole(
        keccak256("JOSEPH_ROLE"),
        admin
    );

    await iporAssetConfigurationProxy.grantRole(
        keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfigurationProxy.grantRole(
        keccak256("ASSET_MANAGEMENT_VAULT_ROLE"),
        admin
    );

    await iporAssetConfigurationProxy.grantRole(
        keccak256("CHARLIE_TREASURER_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfigurationProxy.grantRole(
        keccak256("CHARLIE_TREASURER_ROLE"),
        admin
    );

    await iporAssetConfigurationProxy.grantRole(
        keccak256("TREASURE_TREASURER_ADMIN_ROLE"),
        admin
    );
    await iporAssetConfigurationProxy.grantRole(
        keccak256("TREASURE_TREASURER_ROLE"),
        admin
    );
}
