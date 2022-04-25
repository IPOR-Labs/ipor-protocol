const script = require("../../libs/mocks/0002_setup_testnet_strategy.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
};
