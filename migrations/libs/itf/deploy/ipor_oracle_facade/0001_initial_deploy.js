const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, IporOracleFacadeDataProvider) {
    const usdt = await func.getValue(keys.USDT);
    const usdc = await func.getValue(keys.USDC);
    const dai = await func.getValue(keys.DAI);

    const iporOracle = await func.getValue(keys.ItfIporOracleProxy);

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
    await func.update(keys.ItfIporOracleFacadeDataProviderImpl, iporOracleFacadeDataProviderImpl);
};
