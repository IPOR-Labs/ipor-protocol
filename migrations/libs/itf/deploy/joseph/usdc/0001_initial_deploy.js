const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, ItfJosephUsdc, isPaused) {
    const asset = await func.getValue(keys.USDC);
    const ipToken = await func.getValue(keys.ipUSDC);
    const stanley = await func.getValue(keys.ItfStanleyProxyUsdc);
    const milton = await func.getValue(keys.ItfMiltonProxyUsdc);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyUsdc);

    const josephProxy = await deployProxy(
        ItfJosephUsdc,
        [isPaused, asset, ipToken, milton, miltonStorage, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephImpl = await erc1967.getImplementationAddress(josephProxy.address);

    await func.update(keys.ItfJosephProxyUsdc, josephProxy.address);
    await func.update(keys.ItfJosephImplUsdc, josephImpl);
};
