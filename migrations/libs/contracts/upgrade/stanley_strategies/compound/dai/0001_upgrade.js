const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");
const { erc1967, prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

const MockTestnetStrategyCompoundDaiV2 = artifacts.require("MockTestnetStrategyCompoundDaiV2");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const compoundStrategyProxyDai = await func.getValue(keys.CompoundStrategyProxyDai);

    const compoundStrategyImplDai = await prepareUpgrade(
        compoundStrategyProxyDai,
        MockTestnetStrategyCompoundDaiV2
    );

    await func.update(keys.CompoundStrategyImplDai, compoundStrategyImplDai);
};
