const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAave) {
    const strategyProxyAddress = await func.getValue(keys.AaveStrategyProxyUsdc);

    const strategyImplAddress = await prepareUpgrade(strategyProxyAddress, StrategyAave, {
        deployer: deployer,
        kind: "uups",
    });
    await func.update(keys.AaveStrategyImplUsdc, strategyImplAddress);
};
