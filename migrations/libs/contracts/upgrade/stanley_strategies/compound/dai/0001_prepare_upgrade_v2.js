const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyCompoundDai) {
    const compoundStrategyProxyAddress = await func.getValue(keys.CompoundStrategyProxyDai);

    const compoundStrategyImplAddress = await prepareUpgrade(
        compoundStrategyProxyAddress,
        StrategyCompoundDai,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.CompoundStrategyImplDai, compoundStrategyImplAddress);
};
