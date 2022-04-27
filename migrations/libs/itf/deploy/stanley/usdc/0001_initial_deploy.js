const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfStanleyUsdc) {
    const asset = await func.getValue(keys.USDC);
    const ivToken = await func.getValue(keys.ivUSDC);
    const strategyAave = await func.getValue(keys.AaveStrategyProxyUsdc);
    const strategyCompound = await func.getValue(keys.CompoundStrategyProxyUsdc);

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
