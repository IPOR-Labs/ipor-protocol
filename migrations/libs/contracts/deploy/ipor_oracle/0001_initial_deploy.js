const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, IporOracle, initialParams) {
    const assets = initialParams.assets;
    const updateTimestamps = initialParams.updateTimestamps;
    const exponentialMovingAverages = initialParams.exponentialMovingAverages;
    const exponentialWeightedMovingVariances = initialParams.exponentialWeightedMovingVariances;

    const iporOracleProxy = await deployProxy(
        IporOracle,
        [assets, updateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const iporOracleImpl = await erc1967.getImplementationAddress(iporOracleProxy.address);

    await func.update(keys.IporOracleProxy, iporOracleProxy.address);
    await func.update(keys.IporOracleImpl, iporOracleImpl);
};
