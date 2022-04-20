const keys = require("./json_keys.js");
const func = require("./json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const StrategyAaveDai = artifacts.require("StrategyAaveDai");

module.exports = async function (deployer, _network) {
    const aave = await func.get_value(keys.AAVE);
    const asset = await func.get_value(keys.DAI);
    const aToken = await func.get_value(keys.aDAI);
    const aaveProvider = await func.get_value(keys.AaveProvider);
    const stakedAave = await func.get_value(keys.AaveStaked);
    const aaveIncentivesController = await func.get_value(keys.AaveIncentivesController);

    const aaveStrategyProxyDai = await deployProxy(
        StrategyAaveDai,
        [asset, aToken, aaveProvider, stakedAave, aaveIncentivesController, aave],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const aaveStrategyImplDai = await erc1967.getImplementationAddress(
        aaveStrategyProxyDai.address
    );

    await func.update(keys.AaveStrategyProxyDai, aaveStrategyProxyDai.address);
    await func.update(keys.AaveStrategyImplDai, aaveStrategyImplDai.address);
};
