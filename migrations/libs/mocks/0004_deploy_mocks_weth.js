const keys = require("../json_keys.js");
const func = require("../json_func.js");

module.exports = async function (
    deployer,
    _network,
    addresses,
    MockTestnetTokenWeth
) {
    const stableTotalSupply18Decimals = "1000000000000000000000000000000";

    await deployer.deploy(MockTestnetTokenWeth, stableTotalSupply18Decimals);
    const mockedWeth = await MockTestnetTokenWeth.deployed();
    await func.update(keys.WETH, mockedWeth.address);


};
