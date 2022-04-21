const keys = require("./json_keys.js");
const func = require("../libs/json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MiltonUsdt = artifacts.require("MiltonUsdt");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.USDT);
    const stanley = await func.get_value(keys.StanleyProxyUsdt);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyUsdt);
    const iporOracle = await func.get_value(keys.IporOracleProxy);
    const miltonSpreadModel = await func.get_value(keys.MiltonSpreadModel);

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
    await func.update(keys.MiltonImplUsdt, miltonImpl.address);
};
