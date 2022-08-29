const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAaveUsdt) {
    const aaveStrategyProxyAddress = await func.getValue(keys.AaveStrategyProxyUsdt);

    const aaveStrategyImplAddress = await prepareUpgrade(
        aaveStrategyProxyAddress,
        StrategyAaveUsdt,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.AaveStrategyImplUsdt, aaveStrategyImplAddress);
};
