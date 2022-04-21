const script = require("../../libs/contracts/deploy/iv_token/usdc/0001_initial_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};
