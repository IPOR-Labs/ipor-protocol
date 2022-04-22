const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, IvTokenUsdt) {
    const asset = await func.get_value(keys.USDT);

    await deployer.deploy(IvTokenUsdt, "IV USDT", "ivUSDT", asset);
    const ivTokenUsdt = await IvTokenUsdt.deployed();

    await func.update(keys.ivUSDT, ivTokenUsdt.address);
};
