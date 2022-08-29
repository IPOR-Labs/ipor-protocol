const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StanleyUsdt) {
    const stanleyProxyAddress = await func.getValue(keys.StanleyProxyUsdt);

    const stanleyImplAddress = await prepareUpgrade(stanleyProxyAddress, StanleyUsdt, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.StanleyImplUsdt, stanleyImplAddress);
};
