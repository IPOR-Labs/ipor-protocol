const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAaveUsdc) {
    const aave = await func.get_value(keys.AAVE);
    const asset = await func.get_value(keys.USDC);
    const aToken = await func.get_value(keys.aUSDC);
    const aaveProvider = await func.get_value(keys.AaveProvider);
    const stakedAave = await func.get_value(keys.AaveStaked);
    const aaveIncentivesController = await func.get_value(keys.AaveIncentivesController);

    const aaveStrategyProxy = await deployProxy(
        StrategyAaveUsdc,
        [asset, aToken, aaveProvider, stakedAave, aaveIncentivesController, aave],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const aaveStrategyImpl = await erc1967.getImplementationAddress(aaveStrategyProxy.address);

    await func.update(keys.AaveStrategyProxyUsdc, aaveStrategyProxy.address);
    await func.update(keys.AaveStrategyImplUsdc, aaveStrategyImpl);
};
