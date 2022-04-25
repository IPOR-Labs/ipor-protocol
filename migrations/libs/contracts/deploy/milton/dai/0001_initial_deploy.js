const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonDai) {
    const asset = await func.get_value(keys.DAI);
    const stanley = await func.get_value(keys.StanleyProxyDai);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyDai);
    const iporOracle = await func.get_value(keys.IporOracleProxy);
    const miltonSpreadModel = await func.get_value(keys.MiltonSpreadModel);

    const miltonProxy = await deployProxy(
        MiltonDai,
        [asset, iporOracle, miltonStorage, miltonSpreadModel, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy.address);

    await func.update(keys.MiltonProxyDai, miltonProxy.address);
    await func.update(keys.MiltonImplDai, miltonImpl);
};
