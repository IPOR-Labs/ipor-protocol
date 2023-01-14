const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, TestnetFaucet) {
    const proxyAddress = await func.getValue(keys.TestnetFaucetProxy);

    const implAddress = await prepareUpgrade(proxyAddress, TestnetFaucet, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.TestnetFaucetImpl, implAddress);
};
