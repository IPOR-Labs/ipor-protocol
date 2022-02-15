require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const IporConfiguration = artifacts.require("IporConfiguration");

const IporAssetConfigurationUsdt = artifacts.require(
    "IporAssetConfigurationUsdt"
);
const IporAssetConfigurationUsdc = artifacts.require(
    "IporAssetConfigurationUsdc"
);
const IporAssetConfigurationDai = artifacts.require(
    "IporAssetConfigurationDai"
);

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");

const Warren = artifacts.require("Warren");
const ItfWarren = artifacts.require("ItfWarren");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");
const MiltonStorageUsdc = artifacts.require("MiltonStorageUsdc");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

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
const MiltonDevToolDataProvider = artifacts.require(
    "MiltonDevToolDataProvider"
);
const WarrenFrontendDataProvider = artifacts.require(
    "WarrenFrontendDataProvider"
);
const MiltonFrontendDataProvider = artifacts.require(
    "MiltonFrontendDataProvider"
);

module.exports = async function (deployer, _network, addresses) {
    console.log("Upgrade Smart Contracts...");

    await upgradeContract(IporConfiguration);
    await upgradeContract(IporAssetConfigurationUsdt);
    await upgradeContract(IporAssetConfigurationUsdc);
    await upgradeContract(IporAssetConfigurationDai);
    await upgradeContract(MiltonSpreadModel);

    await upgradeContract(Warren);
    await upgradeContract(ItfWarren);

    await upgradeContract(WarrenDevToolDataProvider);
    await upgradeContract(WarrenFrontendDataProvider);
    await upgradeContract(MiltonDevToolDataProvider);
    await upgradeContract(MiltonFrontendDataProvider);

    await upgradeContract(MiltonStorageUsdt);
    await upgradeContract(MiltonStorageUsdc);
    await upgradeContract(MiltonStorageDai);

    await upgradeContract(MiltonUsdt);
    await upgradeContract(MiltonUsdc);
    await upgradeContract(MiltonDai);
    await upgradeContract(ItfMiltonUsdt);
    await upgradeContract(ItfMiltonUsdc);
    await upgradeContract(ItfMiltonDai);

    await upgradeContract(JosephUsdt);
    await upgradeContract(JosephUsdc);
    await upgradeContract(JosephDai);

    await upgradeContract(ItfJosephUsdt);
    await upgradeContract(ItfJosephUsdc);
    await upgradeContract(ItfJosephDai);

    console.log("Congratulations! Upgrade Smart Contracts...");
};

async function upgradeContract(Contract) {
    const proxy = await Contract.deployed();
    const instance = await upgradeProxy(proxy.address, Contract);
    console.log("Upgraded! ", instance.address);
}
