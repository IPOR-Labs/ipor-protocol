const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfMiltonUsdt) {
    const asset = await func.getValue(keys.USDT);
    const stanley = await func.getValue(keys.ItfStanleyProxyUsdt);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyUsdt);
    const iporOracle = await func.getValue(keys.ItfIporOracleProxy);
    const miltonSpreadModel = await func.getValue(keys.ItfMiltonSpreadModel);

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
