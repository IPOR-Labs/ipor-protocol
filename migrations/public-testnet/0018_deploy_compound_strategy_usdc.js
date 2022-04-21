const keys = require("./json_keys.js");
const func = require("./json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const StrategyCompoundUsdc = artifacts.require("StrategyCompoundUsdc");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.USDC);
    const cToken = await func.get_value(keys.cUSDC);

    const comptroller = await func.get_value(keys.Comptroller);
    const compToken = await func.get_value(keys.COMP);

    const compoundStrategyProxy = await deployProxy(
        StrategyCompoundUsdc,
        [asset, cToken, comptroller, compToken],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const compoundStrategyImpl = await erc1967.getImplementationAddress(
        compoundStrategyProxy.address
    );

    await func.update(keys.CompoundStrategyProxyUsdc, compoundStrategyProxy.address);
    await func.update(keys.CompoundStrategyImplUsdc, compoundStrategyImpl.address);
};
