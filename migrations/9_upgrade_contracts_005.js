require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonUsdt = artifacts.require("MiltonUsdt");
const MiltonUsdc = artifacts.require("MiltonUsdc");
const MiltonDai = artifacts.require("MiltonDai");

const ItfMiltonUsdt = artifacts.require("ItfMiltonUsdt");
const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");
const ItfMiltonDai = artifacts.require("ItfMiltonDai");

module.exports = async function (deployer, _network, addresses) {
    console.log("Upgrade Smart Contracts...");

    await upgradeContract(MiltonUsdt);
    await upgradeContract(MiltonUsdc);
    await upgradeContract(MiltonDai);
    await upgradeContract(ItfMiltonUsdt);
    await upgradeContract(ItfMiltonUsdc);
    await upgradeContract(ItfMiltonDai);

    console.log("Congratulations! Upgrade Smart Contracts...");
};

async function upgradeContract(Contract) {
    const proxy = await Contract.deployed();
    const instance = await upgradeProxy(proxy.address, Contract);
    console.log("Upgraded! ", instance.address);
}
