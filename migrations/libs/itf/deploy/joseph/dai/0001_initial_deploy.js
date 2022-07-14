const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfJosephDai, isPaused) {
    const asset = await func.getValue(keys.DAI);
    const ipToken = await func.getValue(keys.ipDAI);
    const stanley = await func.getValue(keys.ItfStanleyProxyDai);
    const milton = await func.getValue(keys.ItfMiltonProxyDai);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyDai);

    const josephProxy = await deployProxy(
        ItfJosephDai,
        [isPaused, asset, ipToken, milton, miltonStorage, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephImpl = await erc1967.getImplementationAddress(josephProxy.address);

    await func.update(keys.ItfJosephProxyDai, josephProxy.address);
    await func.update(keys.ItfJosephImplDai, josephImpl);
};
