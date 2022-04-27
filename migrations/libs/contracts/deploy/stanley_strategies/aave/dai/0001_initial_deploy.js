const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAaveDai) {
    const aave = await func.getValue(keys.AAVE);
    const asset = await func.getValue(keys.DAI);
    const aToken = await func.getValue(keys.aDAI);
    const aaveProvider = await func.getValue(keys.AaveProvider);
    const stakedAave = await func.getValue(keys.AaveStaked);
    const aaveIncentivesController = await func.getValue(keys.AaveIncentivesController);

    const aaveStrategyProxy = await deployProxy(
        StrategyAaveDai,
        [asset, aToken, aaveProvider, stakedAave, aaveIncentivesController, aave],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const aaveStrategyImpl = await erc1967.getImplementationAddress(aaveStrategyProxy.address);

    await func.update(keys.AaveStrategyProxyDai, aaveStrategyProxy.address);
    await func.update(keys.AaveStrategyImplDai, aaveStrategyImpl);
};
