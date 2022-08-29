const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, StrategyAaveDai) {
    const aaveStrategyProxyAddress = await func.getValue(keys.AaveStrategyProxyDai);

    const aaveStrategyImplAddress = await prepareUpgrade(
        aaveStrategyProxyAddress,
        StrategyAaveDai,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.AaveStrategyImplDai, aaveStrategyImplAddress);
};
