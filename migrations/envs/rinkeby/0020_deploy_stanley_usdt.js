const script = require("../../libs/contracts/deploy/stanley/usdt/0001_initial_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};
