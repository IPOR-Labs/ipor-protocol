const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonUsdt, isPaused) {
    const asset = await func.getValue(keys.USDT);
    const stanley = await func.getValue(keys.StanleyProxyUsdt);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyUsdt);
    const iporOracle = await func.getValue(keys.IporOracleProxy);
    const miltonSpreadModelUsdt = await func.getValue(keys.MiltonSpreadModelUsdt);

    const miltonProxy = await deployProxy(
        MiltonUsdt,
        [isPaused, asset, iporOracle, miltonStorage, miltonSpreadModelUsdt, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy.address);

    await func.update(keys.MiltonProxyUsdt, miltonProxy.address);
    await func.update(keys.MiltonImplUsdt, miltonImpl);
};
