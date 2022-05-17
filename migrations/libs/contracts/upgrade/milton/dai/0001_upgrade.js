require("dotenv").config({ path: "../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonDaiV2 = artifacts.require("MiltonDaiV2");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const miltonProxy = await func.getValue(keys.MiltonProxyDai);

    const upgraded = await upgradeProxy(miltonProxy, MiltonDaiV2);

    const miltonImpl = await erc1967.getImplementationAddress(miltonProxy);

    await func.update(keys.MiltonImplDai, miltonImpl);
};
