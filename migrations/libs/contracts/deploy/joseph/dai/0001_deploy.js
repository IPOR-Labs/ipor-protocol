const keys = require("./json_keys.js");
const func = require("./json_func.js");
const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const JosephDai = artifacts.require("JosephDai");

module.exports = async function (deployer, _network) {
    const asset = await func.get_value(keys.DAI);
    const ipToken = await func.get_value(keys.ipDAI);
    const stanley = await func.get_value(keys.StanleyProxyDai);
    const milton = await func.get_value(keys.MiltonProxyDai);
    const miltonStorage = await func.get_value(keys.MiltonStorageProxyDai);

    const josephProxy = await deployProxy(
        JosephDai,
        [asset, ipToken, milton, miltonStorage, stanley],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );

    const josephImpl = await erc1967.getImplementationAddress(josephProxy.address);

    await func.update(keys.JosephProxyDai, josephProxy.address);
    await func.update(keys.JosephImplDai, josephImpl.address);
};
