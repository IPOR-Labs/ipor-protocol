const keys = require("./json_keys.js");
const func = require("../libs/json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const JosephUsdt = artifacts.require("JosephUsdt");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.USDT);
    const ipToken = await func.get_value(keys.ipUSDT);
    const stanley = await func.get_value(keys.StanleyProxyUsdt);
    const milton = await func.get_value(keys.MiltonProxyUsdt);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyUsdt);

    const josephProxy = await deployProxy(
        JosephUsdt,
        [asset, ipToken, milton, miltonStorage, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephImpl = await erc1967.getImplementationAddress(josephProxy.address);

    await func.update(keys.JosephProxyUsdt, josephProxy.address);
    await func.update(keys.JosephImplUsdt, josephImpl.address);
};
