const keys = require("../json_keys.js");
const func = require("../json_func.js");
const { prepareUpgrade, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (
    deployer,
    _network,
    addresses,
    [
        MockTestnetStrategyAaveUsdt,
        MockTestnetStrategyAaveUsdc,
        MockTestnetStrategyAaveDai,
        MockTestnetStrategyCompoundUsdt,
        MockTestnetStrategyCompoundUsdc,
        MockTestnetStrategyCompoundDai,
    ]
) {
    //AAVE

    const aaveStrategyProxyUsdtAddress = await func.getValue(keys.AaveStrategyProxyUsdt);
    const aaveStrategyImplUsdtAddress = await prepareUpgrade(
        aaveStrategyProxyUsdtAddress,
        MockTestnetStrategyAaveUsdt,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.AaveStrategyImplUsdt, aaveStrategyImplUsdtAddress);

    const aaveStrategyProxyUsdcAddress = await func.getValue(keys.AaveStrategyProxyUsdc);
    const aaveStrategyImplUsdcAddress = await prepareUpgrade(
        aaveStrategyProxyUsdcAddress,
        MockTestnetStrategyAaveUsdc,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.AaveStrategyImplUsdc, aaveStrategyImplUsdcAddress);

    const aaveStrategyProxyDaiAddress = await func.getValue(keys.AaveStrategyProxyDai);
    const aaveStrategyImplDaiAddress = await prepareUpgrade(
        aaveStrategyProxyDaiAddress,
        MockTestnetStrategyAaveDai,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.AaveStrategyImplDai, aaveStrategyImplDaiAddress);

    // Compound

    const compoundStrategyProxyUsdtAddress = await func.getValue(keys.CompoundStrategyProxyUsdt);
    const compoundStrategyImplUsdtAddress = await prepareUpgrade(
        compoundStrategyProxyUsdtAddress,
        MockTestnetStrategyCompoundUsdt,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.CompoundStrategyImplUsdt, compoundStrategyImplUsdtAddress);

    const compoundStrategyProxyUsdcAddress = await func.getValue(keys.CompoundStrategyProxyUsdc);
    const compoundStrategyImplUsdcAddress = await prepareUpgrade(
        compoundStrategyProxyUsdcAddress,
        MockTestnetStrategyCompoundUsdc,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.CompoundStrategyImplUsdc, compoundStrategyImplUsdcAddress);

    const compoundStrategyProxyDaiAddress = await func.getValue(keys.CompoundStrategyProxyDai);
    const compoundStrategyImplDaiAddress = await prepareUpgrade(
        compoundStrategyProxyDaiAddress,
        MockTestnetStrategyCompoundDai,
        {
            deployer: deployer,
            kind: "uups",
        }
    );
    await func.update(keys.CompoundStrategyImplDai, compoundStrategyImplDaiAddress);
};
