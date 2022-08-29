const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StanleyDai) {
    const stanleyProxyAddress = await func.getValue(keys.StanleyProxyDai);

    const stanleyImplAddress = await prepareUpgrade(stanleyProxyAddress, StanleyDai, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.StanleyImplDai, stanleyImplAddress);
};
