const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

module.exports = async function (deployer, _network, addresses, JosephDai, isPaused) {
    const asset = await func.getValue(keys.DAI);
    const ipToken = await func.getValue(keys.ipDAI);
    const stanley = await func.getValue(keys.StanleyProxyDai);
    const milton = await func.getValue(keys.MiltonProxyDai);
    const miltonStorage = await func.getValue(keys.MiltonStorageProxyDai);
	console.log("Joseph DAI isPaused=",isPaused);
    const josephProxy = await deployProxy(
        JosephDai,
        [isPaused, asset, ipToken, milton, miltonStorage, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephImpl = await erc1967.getImplementationAddress(josephProxy.address);

    await func.update(keys.JosephProxyDai, josephProxy.address);
    await func.update(keys.JosephImplDai, josephImpl);
};
