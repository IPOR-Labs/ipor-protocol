require("dotenv").config({ path: "../.env" });
const keccak256 = require("keccak256");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonSpreadModel = artifacts.require("MiltonSpreadModel");
const ItfMiltonDai = artifacts.require("ItfMiltonDai");
const MiltonStorageDai = artifacts.require("MiltonStorageDai");

module.exports = async function (deployer, _network, addresses) {
    const [admin, userOne, userTwo, userThree, _] = addresses;

    console.log("MiltonSpreadeModel going to upgrade ...");
    const miltonSpreadModel = await MiltonSpreadModel.deployed();
    console.log("MiltonSpreadModel deployed ", miltonSpreadModel.address);
    const newMiltonSpreadModel = await upgradeProxy(
        miltonSpreadModel.address,
        MiltonSpreadModel
    );
    console.log("MiltonSpreadModel upgraded! ", newMiltonSpreadModel.address);

    console.log("ItfMiltonDai going to upgrade ...");
    const itfMiltonDai = await ItfMiltonDai.deployed();
    console.log("ItfMiltonDai deployed ", itfMiltonDai.address);
    const newItfMiltonDai = await upgradeProxy(
        itfMiltonDai.address,
        ItfMiltonDai
    );
    console.log("ItfMiltonDai upgraded! ", newItfMiltonDai.address);

    console.log("MiltonStorageDai going to upgrade ...");
    const miltonStorageDai = await MiltonStorageDai.deployed();
    console.log("MiltonStorageDai deployed ", miltonStorageDai.address);
    const newmiltonStorageDai = await upgradeProxy(
        miltonStorageDai.address,
        MiltonStorageDai
    );
    console.log("MiltonStorageDai upgraded! ", newmiltonStorageDai.address);
};
