const script = require("../../libs/contracts/deploy/ip_token/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
};
