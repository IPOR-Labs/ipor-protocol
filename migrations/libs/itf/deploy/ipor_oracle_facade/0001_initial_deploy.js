const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");

module.exports = async function (deployer, _network, addresses) {
    const usdt = await func.get_value(keys.USDT);
    const usdc = await func.get_value(keys.USDC);
    const dai = await func.get_value(keys.DAI);

    const iporOracle = await func.get_value(keys.ItfIporOracleProxy);

    const iporOracleFacadeDataProviderProxy = await deployProxy(
        IporOracleFacadeDataProvider,
        [[dai, usdt, usdc], iporOracle],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const iporOracleFacadeDataProviderImpl = await erc1967.getImplementationAddress(
        iporOracleFacadeDataProviderProxy.address
    );

    await func.update(
        keys.ItfIporOracleFacadeDataProviderProxy,
        iporOracleFacadeDataProviderProxy.address
    );
    await func.update(
        keys.ItfIporOracleFacadeDataProviderImpl,
        iporOracleFacadeDataProviderImpl
    );
};
