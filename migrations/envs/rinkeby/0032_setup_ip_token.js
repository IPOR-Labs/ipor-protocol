const script = require("../../libs/contracts/setup/ip_token/0001_initial_setup.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};
