require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const IporOracle = artifacts.require("IporOracle");
const ItfIporOracle = artifacts.require("ItfIporOracle");
module.exports = async function (deployer, _network, addresses) {
    console.log("Upgrade Smart Contracts...");

    await upgradeContract(IporOracle);
    await upgradeContract(ItfIporOracle);

    console.log("Congratulations! Upgrade Smart Contracts...");
};

async function upgradeContract(Contract) {
    const proxy = await Contract.deployed();
    const instance = await upgradeProxy(proxy.address, Contract);
    console.log("Upgraded! ", instance.address);
}
