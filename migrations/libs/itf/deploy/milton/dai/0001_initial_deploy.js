const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfMiltonDai) {
    const asset = await func.get_value(keys.DAI);
    const stanley = await func.get_value(keys.ItfStanleyProxyDai);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyDai);
    const iporOracle = await func.get_value(keys.ItfIporOracleProxy);
    const miltonSpreadModel = await func.get_value(keys.MiltonSpreadModel);

    const miltonProxy = await deployProxy(
        ItfMiltonDai,
        [asset, iporOracle, miltonStorage, miltonSpreadModel, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy.address);

    await func.update(keys.ItfMiltonProxyDai, miltonProxy.address);
    await func.update(keys.ItfMiltonImplDai, miltonImpl);
};
