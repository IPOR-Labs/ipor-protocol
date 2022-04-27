const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, CockpitDataProvider) {
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

    const ipUSDT = await func.getValue(keys.ipUSDT);
    const ipUSDC = await func.getValue(keys.ipUSDC);
    const ipDAI = await func.getValue(keys.ipDAI);

    const ivUSDT = await func.getValue(keys.ivUSDT);
    const ivUSDC = await func.getValue(keys.ivUSDC);
    const ivDAI = await func.getValue(keys.ivDAI);

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

    await func.update(keys.CockpitDataProviderProxy, cockpitDataProviderProxy.address);
    await func.update(keys.CockpitDataProviderImpl, cockpitDataProviderImpl);
};
