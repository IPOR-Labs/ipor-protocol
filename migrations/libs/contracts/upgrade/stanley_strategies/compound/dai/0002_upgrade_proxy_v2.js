const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { upgradeProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyCompound) {
    const strategyProxyAddress = await func.getValue(keys.CompoundStrategyProxyDai);

    await upgradeProxy(strategyProxyAddress, StrategyCompound);

	const implAddress = await erc1967.getImplementationAddress(strategyProxyAddress);

    await func.update(keys.CompoundStrategyImplDai, implAddress);
};
