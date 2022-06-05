require("dotenv").config({ path: "../../../../../.env" });
const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonUsdtV3 = artifacts.require("MiltonUsdtV3");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const miltonProxy = await func.getValue(keys.MiltonProxyUsdt);

    const upgraded = await upgradeProxy(miltonProxy, MiltonUsdtV3);

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy);

    await func.update(keys.MiltonImplUsdt, miltonImpl);
};
