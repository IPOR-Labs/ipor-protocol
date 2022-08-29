const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyCompoundUsdc) {
    const compoundStrategyProxyAddress = await func.getValue(keys.CompoundStrategyProxyUsdc);

    const compoundStrategyImplAddress = await prepareUpgrade(
        compoundStrategyProxyAddress,
        StrategyCompoundUsdc,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.CompoundStrategyImplUsdc, compoundStrategyImplAddress);
};
