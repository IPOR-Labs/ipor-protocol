const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyCompound) {
    const strategyProxyAddress = await func.getValue(keys.CompoundStrategyProxyUsdc);

    const strategyImplAddress = await upgradeProxy(strategyProxyAddress, StrategyCompound);

    await func.update(keys.CompoundStrategyImplUsdc, strategyImplAddress);
};
