const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, IpTokenUsdt) {
    const asset = await func.get_value(keys.USDT);

    await deployer.deploy(IpTokenUsdt, "IP USDT", "ipUSDT", asset);
    const ipTokenUsdt = await IpTokenUsdt.deployed();

    await func.update(keys.ipUSDT, ipTokenUsdt.address);
};
