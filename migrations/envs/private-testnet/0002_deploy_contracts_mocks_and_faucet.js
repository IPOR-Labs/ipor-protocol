const script = require("../../libs/mocks/0001_deploy_mocks_and_faucet.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
};
