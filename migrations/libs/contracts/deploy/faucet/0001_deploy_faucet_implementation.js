require("dotenv").config({ path: "../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, TestnetFaucet) {
    await deployer.deploy(TestnetFaucet);
    const testnetFaucetImpl = await TestnetFaucet.deployed();
    await func.update(keys.TestnetFaucetImpl, testnetFaucetImpl);

};
