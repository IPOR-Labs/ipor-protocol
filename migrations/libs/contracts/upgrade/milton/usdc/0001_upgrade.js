require("dotenv").config({ path: "../../../../../.env" });
const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonUsdcV2 = artifacts.require("MiltonUsdcV2");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const miltonProxy = await func.getValue(keys.MiltonProxyUsdc);

    const upgraded = await upgradeProxy(miltonProxy, MiltonUsdcV2);

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy);

    await func.update(keys.MiltonImplUsdc, miltonImpl);
};
