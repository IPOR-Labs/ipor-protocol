const script = require("../../libs/contracts/deploy/cockpit/0001_initial_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};
