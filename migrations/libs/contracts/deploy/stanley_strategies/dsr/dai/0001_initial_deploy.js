const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, Strategy) {
    const asset = await func.getValue(keys.DAI);
    const sToken = await func.getValue(keys.sDAI);
    const stanley = await func.getValue(keys.StanleyProxyDai);

    const strategyProxy = await deployProxy(Strategy, [], {
        unsafeAllow: ["constructor", "state-variable-immutable"],
        constructorArgs: [asset, sToken, stanley],
        deployer: deployer,
        initializer: "initialize",
        kind: "uups",
    });

    const strategyImpl = await erc1967.getImplementationAddress(strategyProxy.address);

    await func.update(keys.DsrStrategyProxyDai, strategyProxy.address);
    await func.update(keys.DsrStrategyImplDai, strategyImpl);
};
