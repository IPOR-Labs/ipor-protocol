const keys = require("../../../../json_keys.js");
const func = require("../../../../json_func.js");

module.exports = async function (deployer, _network, addresses, IpTokenWeth) {
    const asset = await func.getValue(keys.WETH);

    await deployer.deploy(IpTokenWeth, "IP WETH", "ipWETH", asset);
    const ipTokenWeth = await IpTokenWeth.deployed();

    await func.update(keys.ipWETH, ipTokenWeth.address);
};
