const keys = require("./json_keys.js");
const func = require("../libs/json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const MiltonUsdc = artifacts.require("MiltonUsdc");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.USDC);
    const stanley = await func.get_value(keys.StanleyProxyUsdc);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyUsdc);
    const iporOracle = await func.get_value(keys.IporOracleProxy);
    const miltonSpreadModel = await func.get_value(keys.MiltonSpreadModel);

    const miltonProxy = await deployProxy(
        MiltonUsdc,
        [asset, iporOracle, miltonStorage, miltonSpreadModel, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy.address);

    await func.update(keys.MiltonProxyUsdc, miltonProxy.address);
    await func.update(keys.MiltonImplUsdc, miltonImpl.address);
};
