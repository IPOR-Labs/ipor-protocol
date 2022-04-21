const keys = require("./json_keys.js");
const func = require("./json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const JosephDai = artifacts.require("JosephDai");

module.exports = async function (deployer, _network) {
    const usdt = await func.get_value(keys.USDT);
    const usdc = await func.get_value(keys.USDC);
    const dai = await func.get_value(keys.DAI);

    const iporOracle = await func.get_value(keys.IporOracleProxy);

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
        keys.IporOracleFacadeDataProviderProxy,
        iporOracleFacadeDataProviderProxy.address
    );
    await func.update(
        keys.IporOracleFacadeDataProviderImpl,
        iporOracleFacadeDataProviderImpl.address
    );
};
