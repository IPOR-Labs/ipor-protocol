const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAaveUsdc) {
    const aaveStrategyProxyAddress = await func.getValue(keys.AaveStrategyProxyUsdc);

    const aaveStrategyImplAddress = await prepareUpgrade(
        aaveStrategyProxyAddress,
        StrategyAaveUsdc,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.AaveStrategyImplUsdc, aaveStrategyImplAddress);
};
