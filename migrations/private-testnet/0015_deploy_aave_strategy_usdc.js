const keys = require("./json_keys.js");
const func = require("./json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const StrategyAaveUsdc = artifacts.require("StrategyAaveUsdc");

module.exports = async function (deployer, _network) {
    const aave = await func.get_value(keys.AAVE);
    const asset = await func.get_value(keys.USDC);
    const aToken = await func.get_value(keys.aUSDC);
    const aaveProvider = await func.get_value(keys.AaveProvider);
    const stakedAave = await func.get_value(keys.AaveStaked);
    const aaveIncentivesController = await func.get_value(keys.AaveIncentivesController);

    const aaveStrategyProxyUsdc = await deployProxy(
        StrategyAaveUsdc,
        [asset, aToken, aaveProvider, stakedAave, aaveIncentivesController, aave],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const aaveStrategyImplUsdc = await erc1967.getImplementationAddress(
        aaveStrategyProxyUsdc.address
    );

    await func.update(keys.AaveStrategyProxyUsdc, aaveStrategyProxyUsdc.address);
    await func.update(keys.AaveStrategyImplUsdc, aaveStrategyImplUsdc.address);
};
