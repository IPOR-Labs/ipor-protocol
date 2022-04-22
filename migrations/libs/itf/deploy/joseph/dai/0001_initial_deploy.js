const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfJosephDai) {
    const asset = await func.get_value(keys.DAI);
    const ipToken = await func.get_value(keys.ipDAI);
    const stanley = await func.get_value(keys.ItfStanleyProxyDai);
    const milton = await func.get_value(keys.ItfMiltonProxyDai);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyDai);

    const josephProxy = await deployProxy(
        ItfJosephDai,
        [asset, ipToken, milton, miltonStorage, stanley],
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
