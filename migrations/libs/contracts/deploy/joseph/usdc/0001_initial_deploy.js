const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, JosephUsdc) {
    const asset = await func.getValue(keys.USDC);
    const ipToken = await func.getValue(keys.ipUSDC);
    const stanley = await func.getValue(keys.StanleyProxyUsdc);
    const milton = await func.getValue(keys.MiltonProxyUsdc);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyUsdc);

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
    await func.update(keys.JosephImplUsdc, josephImpl);
};
