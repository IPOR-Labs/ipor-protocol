require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const TestnetFaucet = artifacts.require("TestnetFaucet");

const IporOracle = artifacts.require("IporOracle");
const ItfIporOracle = artifacts.require("ItfIporOracle");

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

const CockpitDataProvider = artifacts.require("CockpitDataProvider");
const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");
const MiltonFacadeDataProvider = artifacts.require("MiltonFacadeDataProvider");

module.exports = async function (deployer, _network, addresses) {
    console.log("Upgrade Smart Contracts...");

    await upgradeContract(TestnetFaucet);

    await upgradeContract(IporOracle);
    await upgradeContract(ItfIporOracle);

    await upgradeContract(IporOracleFacadeDataProvider);
    await upgradeContract(CockpitDataProvider);
    await upgradeContract(MiltonFacadeDataProvider);

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
