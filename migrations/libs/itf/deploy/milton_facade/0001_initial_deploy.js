const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonFacadeDataProvider) {
    const iporOracle = await func.get_value(keys.ItfIporOracleProxy);

    const usdt = await func.get_value(keys.USDT);
    const usdc = await func.get_value(keys.USDC);
    const dai = await func.get_value(keys.DAI);

    const miltonUsdt = await func.get_value(keys.ItfMiltonProxyUsdt);
    const miltonUsdc = await func.get_value(keys.ItfMiltonProxyUsdc);
    const miltonDai = await func.get_value(keys.ItfMiltonProxyDai);

    const miltonStorageUsdt = await func.get_value(keys.MiltonStorageProxyUsdt);
    const miltonStorageUsdc = await func.get_value(keys.MiltonStorageProxyUsdc);
    const miltonStorageDai = await func.get_value(keys.MiltonStorageProxyDai);

    const josephUsdt = await func.get_value(keys.ItfJosephProxyUsdt);
    const josephUsdc = await func.get_value(keys.ItfJosephProxyUsdc);
    const josephDai = await func.get_value(keys.ItfJosephProxyDai);

    const miltonFacadeDataProviderProxy = await deployProxy(
        MiltonFacadeDataProvider,
        [
            iporOracle,
            [usdt, usdc, dai],
            [miltonUsdt, miltonUsdc, miltonDai],
            [miltonStorageUsdt, miltonStorageUsdc, miltonStorageDai],
            [josephUsdt, josephUsdc, josephDai],
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonFacadeDataProviderImpl = await erc1967.getImplementationAddress(
        miltonFacadeDataProviderProxy.address
    );

    await func.update(keys.ItfMiltonFacadeDataProviderProxy, miltonFacadeDataProviderProxy.address);
    await func.update(keys.ItfMiltonFacadeDataProviderImpl, miltonFacadeDataProviderImpl);
};
