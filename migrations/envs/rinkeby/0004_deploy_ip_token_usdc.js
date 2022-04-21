const script = require("../../libs/contracts/deploy/ip_token/usdc/0001_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};
