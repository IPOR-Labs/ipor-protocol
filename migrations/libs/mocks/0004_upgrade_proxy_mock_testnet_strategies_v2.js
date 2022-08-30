const keys = require("../json_keys.js");
const func = require("../json_func.js");
const { upgradeProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

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
    await upgradeProxy(aaveStrategyProxyUsdtAddress, MockTestnetStrategyAaveUsdt);
    const aaveStrategyImplUsdtAddress = await erc1967.getImplementationAddress(
        aaveStrategyProxyUsdtAddress
    );
    await func.update(keys.AaveStrategyImplUsdt, aaveStrategyImplUsdtAddress);

    const aaveStrategyProxyUsdcAddress = await func.getValue(keys.AaveStrategyProxyUsdc);
    await upgradeProxy(aaveStrategyProxyUsdcAddress, MockTestnetStrategyAaveUsdc);
    const aaveStrategyImplUsdcAddress = await erc1967.getImplementationAddress(
        aaveStrategyProxyUsdcAddress
    );
    await func.update(keys.AaveStrategyImplUsdc, aaveStrategyImplUsdcAddress);

    const aaveStrategyProxyDaiAddress = await func.getValue(keys.AaveStrategyProxyDai);
    await upgradeProxy(aaveStrategyProxyDaiAddress, MockTestnetStrategyAaveDai);
    const aaveStrategyImplDaiAddress = await erc1967.getImplementationAddress(
        aaveStrategyProxyDaiAddress
    );
    await func.update(keys.AaveStrategyImplDai, aaveStrategyImplDaiAddress);

    // Compound

    const compoundStrategyProxyUsdtAddress = await func.getValue(keys.CompoundStrategyProxyUsdt);
    await upgradeProxy(compoundStrategyProxyUsdtAddress, MockTestnetStrategyCompoundUsdt);
    const compoundStrategyImplUsdtAddress = await erc1967.getImplementationAddress(
        compoundStrategyProxyUsdtAddress
    );
    await func.update(keys.CompoundStrategyImplUsdt, compoundStrategyImplUsdtAddress);

    const compoundStrategyProxyUsdcAddress = await func.getValue(keys.CompoundStrategyProxyUsdc);
    await upgradeProxy(compoundStrategyProxyUsdcAddress, MockTestnetStrategyCompoundUsdc);
    const compoundStrategyImplUsdcAddress = await erc1967.getImplementationAddress(
        compoundStrategyProxyUsdcAddress
    );
    await func.update(keys.CompoundStrategyImplUsdc, compoundStrategyImplUsdcAddress);

    const compoundStrategyProxyDaiAddress = await func.getValue(keys.CompoundStrategyProxyDai);
    await upgradeProxy(compoundStrategyProxyDaiAddress, MockTestnetStrategyCompoundDai);
    const compoundStrategyImplDaiAddress = await erc1967.getImplementationAddress(
        compoundStrategyProxyDaiAddress
    );
    await func.update(keys.CompoundStrategyImplDai, compoundStrategyImplDaiAddress);
};
