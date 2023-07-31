const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, Stanley) {
    const asset = await func.getValue(keys.DAI);
    const milton = await func.getValue(keys.MiltonProxyDai);
    const strategyAave = await func.getValue(keys.AaveStrategyProxyDai);
    const strategyCompound = await func.getValue(keys.CompoundStrategyProxyDai);
    const strategyDsr = await func.getValue(keys.DsrStrategyProxyDai);
    const ivToken = await func.getValue(keys.ivDAI);

    const stanleyProxyAddress = await func.getValue(keys.StanleyProxyDai);

    const stanleyImplAddress = await prepareUpgrade(stanleyProxyAddress, Stanley, {
        unsafeAllow: ["constructor", "state-variable-immutable"],
        unsafeAllowRenames: true,
        constructorArgs: [asset, milton, strategyAave, strategyCompound, strategyDsr, ivToken],
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.StanleyImplDai, stanleyImplAddress);
};
