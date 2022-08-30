const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { upgradeProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAave) {
    const strategyProxyAddress = await func.getValue(keys.AaveStrategyProxyUsdt);

    await upgradeProxy(strategyProxyAddress, StrategyAave);

    const implAddress = await erc1967.getImplementationAddress(strategyProxyAddress);

    await func.update(keys.AaveStrategyImplUsdt, implAddress);
};
