const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MiltonFacadeDataProvider = artifacts.require("MiltonFacadeDataProvider");

module.exports = async function (deployer, _network, addresses) {
    const iporOracle = await func.get_value(keys.IporOracleProxy);

    const usdt = await func.get_value(keys.USDT);
    const usdc = await func.get_value(keys.USDC);
    const dai = await func.get_value(keys.DAI);

    const miltonUsdt = await func.get_value(keys.MiltonProxyUsdt);
    const miltonUsdc = await func.get_value(keys.MiltonProxyUsdc);
    const miltonDai = await func.get_value(keys.MiltonProxyDai);

    const miltonStorageUsdt = await func.get_value(keys.MiltonStorageProxyUsdt);
    const miltonStorageUsdc = await func.get_value(keys.MiltonStorageProxyUsdc);
    const miltonStorageDai = await func.get_value(keys.MiltonStorageProxyDai);

    const josephUsdt = await func.get_value(keys.JosephProxyUsdt);
    const josephUsdc = await func.get_value(keys.JosephProxyUsdc);
    const josephDai = await func.get_value(keys.JosephProxyDai);

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
