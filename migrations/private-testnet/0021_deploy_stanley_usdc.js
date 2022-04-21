const keys = require("./json_keys.js");
const func = require("../libs/json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const StanleyUsdc = artifacts.require("StanleyUsdc");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.USDC);
    const ivToken = await func.get_value(keys.ivUSDC);
    const strategyAave = await func.get_value(keys.AaveStrategyProxyUsdc);
    const strategyCompound = await func.get_value(keys.CompoundStrategyProxyUsdc);

    const stanleyProxy = await deployProxy(
        StanleyUsdc,
        [asset, ivToken, strategyAave, strategyCompound],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyImpl = await erc1967.getImplementationAddress(stanleyProxy.address);

    await func.update(keys.StanleyProxyUsdc, stanleyProxy.address);
    await func.update(keys.StanleyImplUsdc, stanleyImpl.address);
};
