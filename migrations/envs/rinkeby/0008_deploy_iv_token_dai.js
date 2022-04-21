const script = require("../../libs/contracts/deploy/iv_token/dai/0001_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};
