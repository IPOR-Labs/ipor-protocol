const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonFacadeDataProvider) {
    const iporOracle = await func.getValue(keys.IporOracleProxy);

    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);

    const miltonUsdt = await func.getValue(keys.MiltonProxyUsdt);
    const miltonUsdc = await func.getValue(keys.MiltonProxyUsdc);
    const miltonDai = await func.getValue(keys.MiltonProxyDai);

    const miltonStorageUsdt = await func.getValue(keys.MiltonStorageProxyUsdt);
    const miltonStorageUsdc = await func.getValue(keys.MiltonStorageProxyUsdc);
    const miltonStorageDai = await func.getValue(keys.MiltonStorageProxyDai);

    const josephUsdt = await func.getValue(keys.JosephProxyUsdt);
    const josephUsdc = await func.getValue(keys.JosephProxyUsdc);
    const josephDai = await func.getValue(keys.JosephProxyDai);

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

    await func.update(keys.MiltonFacadeDataProviderProxy, miltonFacadeDataProviderProxy.address);
    await func.update(keys.MiltonFacadeDataProviderImpl, miltonFacadeDataProviderImpl);
};
