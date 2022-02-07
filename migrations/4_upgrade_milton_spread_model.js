require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;
    const miltonSpreadModel = await MiltonSpreadModel.deployed();
    console.log("MiltonSpreadModel deployed ", miltonSpreadModel.address);
    const instance = await upgradeProxy(
        miltonSpreadModel.address,
        MiltonSpreadModel
    );
    console.log("MiltonSpreadModel upgraded ", instance.address);
};
