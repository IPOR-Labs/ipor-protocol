const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfMiltonWeth, isPaused) {
    const asset = await func.getValue(keys.WETH);
    const stanley = await func.getValue(keys.ItfStanleyProxyWeth);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyWeth);
    const iporOracle = await func.getValue(keys.ItfIporOracleProxy);
    const miltonSpreadModelWeth = await func.getValue(keys.ItfMiltonSpreadModelWeth);

    const miltonProxy = await deployProxy(
        ItfMiltonWeth,
        [isPaused, asset, iporOracle, miltonStorage, miltonSpreadModelWeth, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy.address);

    await func.update(keys.ItfMiltonProxyWeth, miltonProxy.address);
    await func.update(keys.ItfMiltonImplWeth, miltonImpl);
};
