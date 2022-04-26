const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonUsdt) {
    const asset = await func.getValue(keys.USDT);
    const stanley = await func.getValue(keys.StanleyProxyUsdt);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyUsdt);
    const iporOracle = await func.getValue(keys.IporOracleProxy);
    const miltonSpreadModel = await func.getValue(keys.MiltonSpreadModel);

    const miltonProxy = await deployProxy(
        MiltonUsdt,
        [asset, iporOracle, miltonStorage, miltonSpreadModel, stanley],
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
