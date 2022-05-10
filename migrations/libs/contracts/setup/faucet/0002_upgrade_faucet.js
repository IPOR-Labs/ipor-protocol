require("dotenv").config({ path: "../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const TestnetFaucetV2 = artifacts.require("TestnetFaucetV2");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const testnetFaucet = await func.getValue(keys.TestnetFaucetProxy);

    const upgraded = await upgradeProxy(testnetFaucet, TestnetFaucetV2);

    const testnetFaucetImpl = await erc1967.getImplementationAddress(testnetFaucet);

    await func.update(keys.TestnetFaucetImpl, testnetFaucetImpl);
};
