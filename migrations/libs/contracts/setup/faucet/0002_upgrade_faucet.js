require("dotenv").config({ path: "../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const TestnetFaucet = artifacts.require("TestnetFaucet");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const testnetFaucet = await func.getValue(keys.TestnetFaucetProxy);

    const testnetFaucetInstance = await TestnetFaucet.at(testnetFaucet);

    const upgraded = await upgradeProxy(testnetFaucetInstance.address, TestnetFaucet);

    const testnetFaucetImpl = await erc1967.getImplementationAddress(testnetFaucet);

    await func.update(keys.TestnetFaucetImpl, testnetFaucetImpl);
};
