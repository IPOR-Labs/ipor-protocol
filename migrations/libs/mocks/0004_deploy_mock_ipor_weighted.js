const keys = require("../json_keys.js");
const func = require("../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, MockIporWeighted) {
    let iporOracleProxyAddress;
    if (process.env.ITF_ENABLED === "true") {
        iporOracleProxyAddress = await func.getValue(keys.ItfIporOracleProxy);
    } else {
        iporOracleProxyAddress = await func.getValue(keys.IporOracleProxy);
    }
    const iporAlgorithmProxy = await deployProxy(
        MockIporWeighted,
        [iporOracleProxyAddress],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const iporAlgorithmImpl = await erc1967.getImplementationAddress(
        iporAlgorithmProxy.address
    );

    await func.update(keys.IporAlgorithmProxy, iporAlgorithmProxy.address);
    await func.update(keys.IporAlgorithmImpl, iporAlgorithmImpl);
}