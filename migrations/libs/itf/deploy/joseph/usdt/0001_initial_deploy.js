const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfJosephUsdt) {
    const asset = await func.get_value(keys.USDT);
    const ipToken = await func.get_value(keys.ipUSDT);
    const stanley = await func.get_value(keys.ItfStanleyProxyUsdt);
    const milton = await func.get_value(keys.ItfMiltonProxyUsdt);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyUsdt);

    const josephProxy = await deployProxy(
        ItfJosephUsdt,
        [asset, ipToken, milton, miltonStorage, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephImpl = await erc1967.getImplementationAddress(josephProxy.address);

    await func.update(keys.ItfJosephProxyUsdt, josephProxy.address);
    await func.update(keys.ItfJosephImplUsdt, josephImpl);
};
