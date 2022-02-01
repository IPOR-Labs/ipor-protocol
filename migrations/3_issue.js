const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const Issue = artifacts.require("Issue");
const IssueV2 = artifacts.require("IssueV2");

module.exports = async function (deployer) {
    const existing = await Issue.deployed();
    const instance = await upgradeProxy(existing.address, IssueV2, {
        deployer,
    });
    console.log("Upgraded", instance.address);
};
