const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyCompoundUsdt) {
    const compoundStrategyProxyAddress = await func.getValue(keys.CompoundStrategyProxyUsdt);

    const compoundStrategyImplAddress = await prepareUpgrade(
        compoundStrategyProxyAddress,
        StrategyCompoundUsdt,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.CompoundStrategyImplUsdt, compoundStrategyImplAddress);
};
