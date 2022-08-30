const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAave) {
    const strategyProxyAddress = await func.getValue(keys.AaveStrategyProxyUsdc);

    const strategyImplAddress = await upgradeProxy(strategyProxyAddress, StrategyAave);

    await func.update(keys.AaveStrategyImplUsdc, strategyImplAddress);
};
