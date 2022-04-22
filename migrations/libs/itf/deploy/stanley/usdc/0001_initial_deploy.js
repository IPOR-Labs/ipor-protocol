const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const ItfStanleyUsdc = artifacts.require("ItfStanleyUsdc");

module.exports = async function (deployer, _network, addresses) {
    const asset = await func.get_value(keys.USDC);
    const ivToken = await func.get_value(keys.ivUSDC);
    const strategyAave = await func.get_value(keys.AaveStrategyProxyUsdc);
    const strategyCompound = await func.get_value(keys.CompoundStrategyProxyUsdc);

    const stanleyProxy = await deployProxy(
        ItfStanleyUsdc,
        [asset, ivToken, strategyAave, strategyCompound],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const stanleyImpl = await erc1967.getImplementationAddress(stanleyProxy.address);

    await func.update(keys.ItfStanleyProxyUsdc, stanleyProxy.address);
    await func.update(keys.ItfStanleyImplUsdc, stanleyImpl);
};
