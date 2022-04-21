const script = require("../../libs/contracts/deploy/joseph/usdt/0001_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};
