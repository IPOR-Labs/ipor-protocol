const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonDai) {
    const asset = await func.getValue(keys.DAI);
    const stanley = await func.getValue(keys.StanleyProxyDai);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyDai);
    const iporOracle = await func.getValue(keys.IporOracleProxy);
    const miltonSpreadModelDai = await func.getValue(keys.MiltonSpreadModelDai);

    const miltonProxy = await deployProxy(
        MiltonDai,
        [asset, iporOracle, miltonStorage, miltonSpreadModelDai, stanley],
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
