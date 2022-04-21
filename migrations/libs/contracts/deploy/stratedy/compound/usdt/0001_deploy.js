const keys = require("./json_keys.js");
const func = require("./json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const StrategyCompoundUsdt = artifacts.require("StrategyCompoundUsdt");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.USDT);
    const cToken = await func.get_value(keys.cUSDT);

    const comptroller = await func.get_value(keys.Comptroller);
    const compToken = await func.get_value(keys.COMP);

    const compoundStrategyProxy = await deployProxy(
        StrategyCompoundUsdt,
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

    await func.update(keys.CompoundStrategyProxyUsdt, compoundStrategyProxy.address);
    await func.update(keys.CompoundStrategyImplUsdt, compoundStrategyImpl.address);
};
