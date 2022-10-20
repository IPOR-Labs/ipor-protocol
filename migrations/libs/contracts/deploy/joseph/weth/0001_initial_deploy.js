const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, JosephWeth, isPaused) {
    const asset = await func.getValue(keys.WETH);
    const ipToken = await func.getValue(keys.ipWETH);
    const stanley = await func.getValue(keys.StanleyProxyWeth);
    const milton = await func.getValue(keys.MiltonProxyWeth);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyWeth);
    const josephProxy = await deployProxy(
        JosephWeth,
        [isPaused, asset, ipToken, milton, miltonStorage, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephImpl = await erc1967.getImplementationAddress(josephProxy.address);

    await func.update(keys.JosephProxyWeth, josephProxy.address);
    await func.update(keys.JosephImplWeth, josephImpl);
};
