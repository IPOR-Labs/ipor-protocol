const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyCompound) {
    const strategyProxyAddress = await func.getValue(keys.CompoundStrategyProxyDai);

    const strategyImplAddress = await prepareUpgrade(strategyProxyAddress, StrategyCompound, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.CompoundStrategyImplDai, strategyImplAddress);
};
