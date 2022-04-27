const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyCompoundUsdt) {
    const asset = await func.getValue(keys.USDT);
    const cToken = await func.getValue(keys.cUSDT);

    const comptroller = await func.getValue(keys.Comptroller);
    const compToken = await func.getValue(keys.COMP);

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
    await func.update(keys.CompoundStrategyImplUsdt, compoundStrategyImpl);
};
