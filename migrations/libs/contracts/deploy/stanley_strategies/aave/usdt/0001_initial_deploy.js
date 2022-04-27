const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAaveUsdt) {
    const aave = await func.getValue(keys.AAVE);
    const asset = await func.getValue(keys.USDT);
    const aToken = await func.getValue(keys.aUSDT);
    const aaveProvider = await func.getValue(keys.AaveProvider);
    const stakedAave = await func.getValue(keys.AaveStaked);
    const aaveIncentivesController = await func.getValue(keys.AaveIncentivesController);

    const aaveStrategyProxy = await deployProxy(
        StrategyAaveUsdt,
        [asset, aToken, aaveProvider, stakedAave, aaveIncentivesController, aave],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const aaveStrategyImpl = await erc1967.getImplementationAddress(aaveStrategyProxy.address);

    await func.update(keys.AaveStrategyProxyUsdt, aaveStrategyProxy.address);
    await func.update(keys.AaveStrategyImplUsdt, aaveStrategyImpl);
};
