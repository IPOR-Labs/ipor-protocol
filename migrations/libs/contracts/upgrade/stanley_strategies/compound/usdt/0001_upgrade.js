const keys = require("../../../../../json_keys.js");
const func = require("../../../../../json_func.js");
const { erc1967, prepareUpgrade } = require("@openzeppelin/truffle-upgrades");

const MockTestnetStrategyCompoundUsdtV2 = artifacts.require("MockTestnetStrategyCompoundUsdtV2");

module.exports = async function (deployer, _network, addresses) {
    const [admin, iporIndexAdmin, _] = addresses;

    const compoundStrategyProxyUsdt = await func.getValue(keys.CompoundStrategyProxyUsdt);

    const compoundStrategyImplUsdt = await prepareUpgrade(
        compoundStrategyProxyUsdt,
        MockTestnetStrategyCompoundUsdtV2
    );

    await func.update(keys.CompoundStrategyImplUsdt, compoundStrategyImplUsdt);
};
