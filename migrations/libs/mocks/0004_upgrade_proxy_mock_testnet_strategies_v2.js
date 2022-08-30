const keys = require("../json_keys.js");
const func = require("../json_func.js");
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

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
    const aaveStrategyImplUsdtAddress = await upgradeProxy(
        aaveStrategyProxyUsdtAddress,
        MockTestnetStrategyAaveUsdt
    );
    await func.update(keys.AaveStrategyImplUsdt, aaveStrategyImplUsdtAddress);

    const aaveStrategyProxyUsdcAddress = await func.getValue(keys.AaveStrategyProxyUsdc);
    const aaveStrategyImplUsdcAddress = await upgradeProxy(
        aaveStrategyProxyUsdcAddress,
        MockTestnetStrategyAaveUsdc
    );
    await func.update(keys.AaveStrategyImplUsdc, aaveStrategyImplUsdcAddress);

    const aaveStrategyProxyDaiAddress = await func.getValue(keys.AaveStrategyProxyDai);
    const aaveStrategyImplDaiAddress = await upgradeProxy(
        aaveStrategyProxyDaiAddress,
        MockTestnetStrategyAaveDai
    );
    await func.update(keys.AaveStrategyImplDai, aaveStrategyImplDaiAddress);

    // Compound

    const compoundStrategyProxyUsdtAddress = await func.getValue(keys.CompoundStrategyProxyUsdt);
    const compoundStrategyImplUsdtAddress = await upgradeProxy(
        compoundStrategyProxyUsdtAddress,
        MockTestnetStrategyCompoundUsdt
    );
    await func.update(keys.CompoundStrategyImplUsdt, compoundStrategyImplUsdtAddress);

    const compoundStrategyProxyUsdcAddress = await func.getValue(keys.CompoundStrategyProxyUsdc);
    const compoundStrategyImplUsdcAddress = await upgradeProxy(
        compoundStrategyProxyUsdcAddress,
        MockTestnetStrategyCompoundUsdc
    );
    await func.update(keys.CompoundStrategyImplUsdc, compoundStrategyImplUsdcAddress);

    const compoundStrategyProxyDaiAddress = await func.getValue(keys.CompoundStrategyProxyDai);
    const compoundStrategyImplDaiAddress = await upgradeProxy(
        compoundStrategyProxyDaiAddress,
        MockTestnetStrategyCompoundDai
    );
    await func.update(keys.CompoundStrategyImplDai, compoundStrategyImplDaiAddress);
};
