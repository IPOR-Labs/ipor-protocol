const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MiltonUsdc) {
    const asset = await func.getValue(keys.USDC);
    const stanley = await func.getValue(keys.StanleyProxyUsdc);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyUsdc);
    const iporOracle = await func.getValue(keys.IporOracleProxy);
    const miltonSpreadModel = await func.getValue(keys.MiltonSpreadModel);

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
    await func.update(keys.MiltonImplUsdc, miltonImpl);
};
