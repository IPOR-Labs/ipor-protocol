const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const CockpitDataProvider = artifacts.require("CockpitDataProvider");

module.exports = async function (deployer, _network, addresses) {
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

    const ipUSDT = await func.get_value(keys.ipUSDT);
    const ipUSDC = await func.get_value(keys.ipUSDC);
    const ipDAI = await func.get_value(keys.ipDAI);

    const ivUSDT = await func.get_value(keys.ivUSDT);
    const ivUSDC = await func.get_value(keys.ivUSDC);
    const ivDAI = await func.get_value(keys.ivDAI);

    const cockpitDataProviderProxy = await deployProxy(
        CockpitDataProvider,
        [
            iporOracle,
            [usdt, usdc, dai],
            [miltonUsdt, miltonUsdc, miltonDai],
            [miltonStorageUsdt, miltonStorageUsdc, miltonStorageDai],
            [josephUsdt, josephUsdc, josephDai],
            [ipUSDT, ipUSDC, ipDAI],
            [ivUSDT, ivUSDC, ivDAI],
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const cockpitDataProviderImpl = await erc1967.getImplementationAddress(
        cockpitDataProviderProxy.address
    );

    await func.update(keys.ItfCockpitDataProviderProxy, cockpitDataProviderProxy.address);
    await func.update(keys.ItfCockpitDataProviderImpl, cockpitDataProviderImpl);
};
