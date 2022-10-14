const keys = require("../json_keys.js");
const func = require("../json_func.js");

module.exports = async function (
    deployer,
    _network,
    addresses,
    WethMockedToken
) {
    let stableTotalSupply18Decimals = "1000000000000000000000000000000";

    await deployer.deploy(WethMockedToken, stableTotalSupply18Decimals);
    const mockedWeth = await WethMockedToken.deployed();
    await func.update(keys.WETH, mockedWeth.address);


};
