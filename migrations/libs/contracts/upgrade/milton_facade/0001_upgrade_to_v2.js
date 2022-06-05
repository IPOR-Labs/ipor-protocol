const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");
const { erc1967, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const MiltonFacadeDataProviderV2 = artifacts.require("MiltonFacadeDataProviderV2");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const miltonFacadeDataProviderProxy = await func.getValue(keys.MiltonFacadeDataProviderProxy);

    const upgraded = await upgradeProxy(miltonFacadeDataProviderProxy, MiltonFacadeDataProviderV2);

    const miltonFacadeDataProviderImpl = await erc1967.getImplementationAddress(
        miltonFacadeDataProviderProxy
    );

    await func.update(keys.MiltonFacadeDataProviderImpl, miltonFacadeDataProviderImpl);
};
