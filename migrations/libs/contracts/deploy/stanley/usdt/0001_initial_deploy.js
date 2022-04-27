const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StanleyUsdt) {
    const asset = await func.getValue(keys.USDT);
    const ivToken = await func.getValue(keys.ivUSDT);
    const strategyAave = await func.getValue(keys.AaveStrategyProxyUsdt);
    const strategyCompound = await func.getValue(keys.CompoundStrategyProxyUsdt);

    const stanleyProxy = await deployProxy(
        StanleyUsdt,
        [asset, ivToken, strategyAave, strategyCompound],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyImpl = await erc1967.getImplementationAddress(stanleyProxy.address);

    await func.update(keys.StanleyProxyUsdt, stanleyProxy.address);
    await func.update(keys.StanleyImplUsdt, stanleyImpl);
};
