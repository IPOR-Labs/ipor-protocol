const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const ItfStanleyUsdt = artifacts.require("ItfStanleyUsdt");

module.exports = async function (deployer, _network, addresses) {
    const asset = await func.get_value(keys.USDT);
    const ivToken = await func.get_value(keys.ivUSDT);
    const strategyAave = await func.get_value(keys.AaveStrategyProxyUsdt);
    const strategyCompound = await func.get_value(keys.CompoundStrategyProxyUsdt);

    const stanleyProxy = await deployProxy(
        ItfStanleyUsdt,
        [asset, ivToken, strategyAave, strategyCompound],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyImpl = await erc1967.getImplementationAddress(stanleyProxy.address);

    await func.update(keys.ItfStanleyProxyUsdt, stanleyProxy.address);
    await func.update(keys.ItfStanleyImplUsdt, stanleyImpl);
};
