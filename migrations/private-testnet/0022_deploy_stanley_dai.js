const keys = require("./json_keys.js");
const func = require("../libs/json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const StanleyDai = artifacts.require("StanleyDai");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.DAI);
    const ivToken = await func.get_value(keys.ivDAI);
    const strategyAave = await func.get_value(keys.AaveStrategyProxyDai);
    const strategyCompound = await func.get_value(keys.CompoundStrategyProxyDai);

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
    await func.update(keys.StanleyImplDai, stanleyImpl.address);
};
