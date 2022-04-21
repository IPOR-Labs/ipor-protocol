const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const JosephUsdc = artifacts.require("JosephUsdc");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.USDC);
    const ipToken = await func.get_value(keys.ipUSDC);
    const stanley = await func.get_value(keys.StanleyProxyUsdc);
    const milton = await func.get_value(keys.MiltonProxyUsdc);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyUsdc);

    const josephProxy = await deployProxy(
        JosephUsdc,
        [asset, ipToken, milton, miltonStorage, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephImpl = await erc1967.getImplementationAddress(josephProxy.address);

    await func.update(keys.JosephProxyUsdc, josephProxy.address);
    await func.update(keys.JosephImplUsdc, josephImpl.address);
};
