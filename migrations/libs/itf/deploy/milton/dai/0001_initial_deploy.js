const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfMiltonDai) {
    const asset = await func.getValue(keys.DAI);
    const stanley = await func.getValue(keys.ItfStanleyProxyDai);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyDai);
    const iporOracle = await func.getValue(keys.ItfIporOracleProxy);
    const miltonSpreadModelDai = await func.getValue(keys.ItfMiltonSpreadModelDai);

    const miltonProxy = await deployProxy(
        ItfMiltonDai,
        [asset, iporOracle, miltonStorage, miltonSpreadModelDai, stanley],
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
