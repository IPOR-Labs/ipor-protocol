const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StanleyDai) {
    const asset = await func.getValue(keys.DAI);
    const ivToken = await func.getValue(keys.ivDAI);
    const strategyAave = await func.getValue(keys.AaveStrategyProxyDai);
    const strategyCompound = await func.getValue(keys.CompoundStrategyProxyDai);

    const stanleyProxy = await deployProxy(
        StanleyDai,
        [asset, ivToken, strategyAave, strategyCompound],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyImpl = await erc1967.getImplementationAddress(stanleyProxy.address);

    await func.update(keys.StanleyProxyDai, stanleyProxy.address);
    await func.update(keys.StanleyImplDai, stanleyImpl);
};