const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const ItfMiltonUsdc = artifacts.require("ItfMiltonUsdc");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.USDC);
    const stanley = await func.get_value(keys.ItfStanleyProxyUsdc);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyUsdc);
    const iporOracle = await func.get_value(keys.ItfIporOracleProxy);
    const miltonSpreadModel = await func.get_value(keys.MiltonSpreadModel);

    const miltonProxy = await deployProxy(
        ItfMiltonUsdc,
        [asset, iporOracle, miltonStorage, miltonSpreadModel, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy.address);

    await func.update(keys.ItfMiltonProxyUsdc, miltonProxy.address);
    await func.update(keys.ItfMiltonImplUsdc, miltonImpl);
};
