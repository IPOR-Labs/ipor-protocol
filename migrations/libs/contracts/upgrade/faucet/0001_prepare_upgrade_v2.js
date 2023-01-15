const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, TestnetFaucet) {
    await deployer.deploy(TestnetFaucet);
    const implAddress = await TestnetFaucet.deployed();

    await func.update(keys.TestnetFaucetImpl, implAddress.address);
};
