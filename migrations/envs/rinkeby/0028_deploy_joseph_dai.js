const script = require("../../libs/contracts/deploy/joseph/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};
