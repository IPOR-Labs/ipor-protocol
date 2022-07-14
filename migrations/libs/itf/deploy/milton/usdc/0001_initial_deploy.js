const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfMiltonUsdc, isPaused) {
    const asset = await func.getValue(keys.USDC);
    const stanley = await func.getValue(keys.ItfStanleyProxyUsdc);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyUsdc);
    const iporOracle = await func.getValue(keys.ItfIporOracleProxy);
    const miltonSpreadModelUsdc = await func.getValue(keys.ItfMiltonSpreadModelUsdc);

    const miltonProxy = await deployProxy(
        ItfMiltonUsdc,
        [isPaused, asset, iporOracle, miltonStorage, miltonSpreadModelUsdc, stanley],
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
