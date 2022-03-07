require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonUsdt = artifacts.require("MiltonUsdt");

module.exports = async function (deployer, _network, addresses) {
    console.log("Upgrade Smart Contracts...");

    await upgradeContract(MiltonUsdt);

    console.log("Congratulations! Upgrade Smart Contracts...");
};

async function upgradeContract(Contract) {
    const proxy = await Contract.deployed();
    const instance = await upgradeProxy(proxy.address, Contract);
    console.log("Upgraded! ", instance.address);
}
