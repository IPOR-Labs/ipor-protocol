const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfMiltonUsdt) {
    const asset = await func.get_value(keys.USDT);
    const stanley = await func.get_value(keys.ItfStanleyProxyUsdt);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyUsdt);
    const iporOracle = await func.get_value(keys.ItfIporOracleProxy);
    const miltonSpreadModel = await func.get_value(keys.MiltonSpreadModel);

    const miltonProxy = await deployProxy(
        ItfMiltonUsdt,
        [asset, iporOracle, miltonStorage, miltonSpreadModel, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy.address);

    await func.update(keys.ItfMiltonProxyUsdt, miltonProxy.address);
    await func.update(keys.ItfMiltonImplUsdt, miltonImpl);
};
