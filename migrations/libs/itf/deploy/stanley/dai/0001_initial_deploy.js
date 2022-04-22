const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const ItfStanleyDai = artifacts.require("ItfStanleyDai");

module.exports = async function (deployer, _network, addresses) {
    const asset = await func.get_value(keys.DAI);
    const ivToken = await func.get_value(keys.ivDAI);
    const strategyAave = await func.get_value(keys.AaveStrategyProxyDai);
    const strategyCompound = await func.get_value(keys.CompoundStrategyProxyDai);

    const stanleyProxy = await deployProxy(
        ItfStanleyDai,
        [asset, ivToken, strategyAave, strategyCompound],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyImpl = await erc1967.getImplementationAddress(stanleyProxy.address);

    await func.update(keys.ItfStanleyProxyDai, stanleyProxy.address);
    await func.update(keys.ItfStanleyImplDai, stanleyImpl);
};
