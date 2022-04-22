const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");
const ItfIporOracle = artifacts.require("ItfIporOracle");

module.exports = async function (deployer, _network) {
    const iporOracleProxy = await deployProxy(ItfIporOracle, {
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const iporOracleImpl = await erc1967.getImplementationAddress(iporOracleProxy.address);

    await func.update(keys.ItfIporOracleProxy, iporOracleProxy.address);
    await func.update(keys.ItfIporOracleImpl, iporOracleImpl);
};
