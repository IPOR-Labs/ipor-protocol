const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfDataProvider) {
    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);

    const assets = [usdt, usdc, dai];

    const miltonUsdt = await func.getValue(keys.ItfMiltonProxyUsdt);
    const miltonUsdc = await func.getValue(keys.ItfMiltonProxyUsdc);
    const miltonDai = await func.getValue(keys.ItfMiltonProxyDai);

    const miltons = [miltonUsdt, miltonUsdc, miltonDai];

    const miltonStorageUsdt = await func.getValue(keys.MiltonStorageProxyUsdt);
    const miltonStorageUsdc = await func.getValue(keys.MiltonStorageProxyUsdc);
    const miltonStorageDai = await func.getValue(keys.MiltonStorageProxyDai);

    const miltonStorages = [miltonStorageUsdt, miltonStorageUsdc, miltonStorageDai];

    const iporOracle = await func.getValue(keys.ItfIporOracleProxy);

    const miltonSpreadModelUsdt = await func.getValue(keys.ItfMiltonSpreadModelUsdt);
    const miltonSpreadModelUsdc = await func.getValue(keys.ItfMiltonSpreadModelUsdc);
    const miltonSpreadModelDai = await func.getValue(keys.ItfMiltonSpreadModelDai);

    const miltonSpreadModels = [miltonSpreadModelUsdt, miltonSpreadModelUsdc, miltonSpreadModelDai];

    const itfDataProviderProxy = await deployProxy(
        ItfDataProvider,
        [assets, miltons, miltonStorages, iporOracle, miltonSpreadModels],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const itfDataProviderImpl = await erc1967.getImplementationAddress(
        itfDataProviderProxy.address
    );

    await func.update(keys.ItfDataProviderProxy, itfDataProviderProxy.address);
    await func.update(keys.ItfDataProviderImpl, itfDataProviderImpl);
};
