const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StanleyUsdc) {
    const stanleyProxyAddress = await func.getValue(keys.StanleyProxyUsdc);

    const stanleyImplAddress = await prepareUpgrade(stanleyProxyAddress, StanleyUsdc, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.StanleyImplUsdc, stanleyImplAddress);
};
